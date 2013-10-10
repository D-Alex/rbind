
require 'rbind/clang/clang'
require 'rbind'
require 'pp'
require 'hooks'

module Rbind
    class ClangParser < RNamespace
        class ClangParserError < RuntimeError
            def initialize(message,cursor)
                @cursor = cursor
                super(message)
            end

            def context(before = 10)
                file,row,cloumn = @cursor.location
                f = File.open(file)
                lines = f.readlines[[0,row-before].max..row-1]
                f.close
                lines
            end

            def to_s
                location = @cursor.location
                con = context
                row = location[1] - con.size
                con = con.map do |line|
                    row += 1
                    "#{row}:\t> #{line}"
                end
                pos_width = @cursor.location_int-@cursor.extent[:begin_int_data]
                pos_start = [location[2]-pos_width,0].max
                con << "   \t " + " "*pos_start + "."*pos_width
                "#{super}\n\n#{"#"*5}\nParsed File: #{location.join(":")}\n#{con.join()}\n#{"#"*5}\n\n"
            rescue Exception => e
                pp e
            end
        end

        include Hooks
        extend ::Rbind::Logger

        def self.default_arguments
            @default_arguments || ["-xc++","-fno-rtti"]
        end

        def self.default_arguments=(args)
            if not args.kind_of?(Array)
                raise ArgumentError, "Clang::default_arguments require Array"
            end
            @default_arguments = args
        end

        def self.reset_default_arguments
            @default_arguments = []
        end

        def initialize(root=nil)
            super(nil,root)
            add_default_types if !root
            @clang = Clang::Clang.new
        end

        def parse(file_path, args = ClangParser.default_arguments)
            tu = @clang.translation_unit(file_path,args)
            process(tu.cursor)
            self
        end

        def normalize_accessor(accessor)
            case accessor
            when :x_public
                :public
            when :x_private
                :private
            when :x_protected
                :protected
            else
                raise "Cannot normalize accessor #{accessor}"
            end
        end

        #returns the real type and the pointer level
        # char** would be returned as [char,2]
        def pointee_type(clang_type)
            # count pointer level
            level = 0
            while(clang_type.kind == :pointer)
                clang_type = clang_type.pointee_type
                level += 1
            end
            [clang_type,level]
        end

        # if rbind_type is given only pointer/ref or qualifier are applied
        def to_rbind_type(parent,cursor,rbind_type=nil,type_getter = :type,canonical = true, use_fallback = true)
            ClangParser.log.debug "Parent: #{parent} --> cursor: #{cursor.expression}, spelling #{cursor.spelling}"
            clang_type = cursor.send(type_getter)
            return nil if clang_type.null?
            clang_type = clang_type.canonical_type if canonical
            clang_type,level = pointee_type(clang_type)

            t = if rbind_type
                    rbind_type
                else
                    name = clang_type.declaration.spelling
                    name = if name.empty?
                               if clang_type.kind != :unexposed
                                   if clang_type.kind == :l_value_reference
                                       clang_type.pointee_type.kind
                                   else
                                       clang_type.kind.to_s
                                   end
                               else
                                   # fall back to cursor spelling
                                   cursor.spelling
                               end
                           else
                               namespace = clang_type.declaration.namespace
                               if namespace.empty?
                                   name
                               else
                                   "#{namespace}::#{name}"
                               end

                           end
                    t = parent.type(name,!canonical)
                end

            # try again without canonical when type could not be found or type is template
            if use_fallback
                if !t || t.template?
                    return to_rbind_type(parent,cursor,rbind_type,type_getter,false, false)
                end
            end

            # add pointer level
            1.upto(level) do
                t = t.to_ptr
            end
            t = if clang_type.kind == :l_value_reference
                    if clang_type.pointee_type.const_qualified?
                        t.to_ref.to_const
                    else
                        t.to_ref
                    end
                else
                    if clang_type.const_qualified?
                        t.to_const
                    else
                        t
                    end
                end
        end

        # entry call to parse a file
        def process(cursor, parent = self, access = :public)
            last_obj = nil
            cursor.visit_children(false) do |cu,cu_parent|
                ClangParser.log.debug "process ----->#{cu.kind} #{cu.spelling} #{cu.type.kind} #{cu.specialized_template.kind} ---> expr: #{cu.expression.join('|')} -- public: #{cu.public?} access: #{access}"
                begin
                    last_obj = case cu.kind
                               when :namespace
                                   process_namespace(cu,parent)
                               when :enum_decl
                                   process_enum(cu,parent) if access == :public
                               when :union_decl
                                   #        puts "got union declaration #{cu.spelling}"
                               when :struct_decl
                                   process_class(cu,parent,:public) if access == :public
                               when :class_decl
                                   process_class(cu,parent, :private) if access == :public
                               when :function_decl
                                   process_function(cu,parent) if access == :public
                               when :macro_expansion # CV_WRAP ...
                                   #           puts "got macro #{cu.spelling} #{cu.location}"
                               when :function_template
                                   #        puts "got template fuction #{cu.spelling} #{cu.location}"
                               when :class_template
                                   process_class_template(cu,parent, access) if access == :public
                               when :template_type_parameter
                                      if !cu.spelling.empty?
                                          parent.add_type(RTemplateParameter.new(cu.spelling))
                                      else
                                          ClangParser.log.info "no template parameter name"
                                      end
                               when :x_access_specifier
                                   access = normalize_accessor(cu.cxx_access_specifier)
                               when :x_base_specifier
                                   if access == :public
                                       next
                                   end
                                   local_access = normalize_accessor(cu.cxx_access_specifier)
                                   klass_name = cu.spelling
                                   if cu.spelling =~ /\s?([^\s]+$)/
                                       klass_name = $1
                                   end
                                   ClangParser.log.info "auto add parent class #{klass_name} if needed"
                                   p = parent.type(RClass.new(RBase.normalize(klass_name)), true)
                                   parent.add_parent p,local_access
                               when :field_decl
                                   process_field(cu,parent) if access == :public
                               when :constructor
                                   if access == :public
                                       f = process_function(cu,parent)
                                       f.return_type = nil if f
                                       f
                                   end
                               when :x_method
                                   process_function(cu,parent) if access == :public
                               when :typedef_decl
                                   if access != :public
                                       next
                                   end
                                   # rename object if parent has no name
                                   if last_obj && last_obj.respond_to?(:name) && last_obj.name =~ /no_name/
                                       ClangParser.log.info "rename #{last_obj.name} to #{cu.spelling}"
                                       last_obj.rename(cu.spelling)
                                       last_obj
                                   else
                                       process_typedef(cu, parent)
                                   end
                               when :var_decl
                                   process_variable(cu,parent) if access == :public
                               when :unexposed_decl
                                   process(cu) if access == :public
                               else
                                   #puts "skip: #{cu.spelling}"
                               end
                    rescue Exception => e
                        ClangParser.log.debug "Parsing failed -- skipping"
                    end
                    raise ClangParserError.new("jjj",cu) if last_obj.is_a? Fixnum


            end
        end

        def process_namespace(cursor,parent)
            name = cursor.spelling
            ClangParser.log.info "processing namespace #{parent}::#{name}"
            ns = parent.add_namespace(name)
            process(cursor,ns)
            ns
        end

        def process_enum(cursor,parent)
            name = cursor.spelling
            name = if name.empty?
                       n = 0.upto(10000) do |i|
                           n = "no_name_enum_#{i}"
                           break n if !parent.type(n,false,false)
                       end
                       raise "Cannot find unique enum name" unless n
                       n
                   else
                       name
                   end
            ClangParser.log.info "processing enum #{parent}::#{name}"
            enum = REnum.new(name)
            cursor.visit_children(false) do |cu,_|
                case cu.kind
                when :enum_constant_decl
                    # for now there is no api to access these values from libclang
                    expression = cu.expression
                    expression.pop
                    val = if expression.join(" ") =~ /=(.*)/
                              $1.gsub(" ","")
                          end
                    enum.add_value(cu.spelling,val)
                end
            end
            parent.add_type(enum)
            enum
        end

        def process_variable(cursor,parent)
            name = cursor.spelling
            ClangParser.log.info "processing variable #{parent}::#{name}"
            var =  process_parameter(cursor,parent)
            if var.type.const?
                parent.add_const(var)
            end
            var
        end

        def process_field(cursor,parent)
            name = cursor.spelling
            ClangParser.log.info "processing field #{parent}::#{name}"
            var =  process_parameter(cursor,parent)
            # TODO check for read write access
            a = RAttribute.new(var.name,var.type).writeable!
            parent.add_attribute a
            a
        end

        def process_class_template(cursor,parent,access)
            class_name = cursor.spelling
            ClangParser.log.info "processing class template #{parent}::#{class_name}"

            klass = parent.type(class_name,false)
            klass = if(!klass)
                        klass = RTemplateClass.new(class_name)
                        parent.add_type(klass)
                        klass
                    else
                        ClangParser.log.info " reopening existing class template #{klass}"
                        klass
                    end
            process(cursor,klass, access)
            klass
        end

        def process_class(cursor,parent,access)
            class_name = cursor.spelling
            class_name = if class_name.empty?
                             "no_name_class"
                         else
                             class_name
                         end
            if cursor.incomplete?
                ClangParser.log.info "skipping incomplete class #{parent}::#{class_name}"
                return
            else
                ClangParser.log.info "processing class #{parent}::#{class_name}"
            end

            klass = parent.type(class_name,false)
            klass = if(!klass)
                        klass = RClass.new(class_name)
                        parent.add_type(klass)
                        klass
                    else
                        if klass.empty?
                            ClangParser.log.info " reopening existing class #{klass}"
                            klass
                        elsif klass.template?
                            ClangParser.log.info " skipping template #{name}"
                            nil
                        else
                            ClangParser.log.warn " skipping non empty class #{name}"
                            #raise "Cannot reopening existing class #{klass} which is non-empty!"
                            nil
                        end
                    end
            #klass.extern_package_name = nil
            process(cursor,klass,access) if klass
            klass
        end

        def process_function(cursor,parent)
            name = cursor.spelling
            args = []

            cursor = if(cursor.specialized_template.kind == :function_template)
                         cursor.specialized_template
                     else
                         cursor
                     end
            cursor.visit_children() do |cu,_|
                case cu.kind
                when :parm_decl
                    p = process_parameter(cu,parent)
                    args << p
                end
            end

            # some default values are not parsed by clang
            # try to parse them from Tokens
            # and rename parameters with unknown name
            # to prevent name clashes
            expression = cursor.expression.join()
            args.each_with_index do |arg,idx|
                if(!arg.default_value && (expression =~ /#{arg.name}(=\w*)?[,)]/))
                    if $1 and !$1.empty?
                        arg.default_value = $1.sub("=","")
                    end
                end
                arg.name = if(arg.name == "no_name_arg")
                               arg.name + idx.to_s
                           else
                               arg.name
                           end
            end

            result_type = if !cursor.result_type.null?
                              process_parameter(cursor,parent,:result_type).type
                          end
            op = ::Rbind::ROperation.new(name,result_type,*args)
            op = if cursor.static?
                     op.to_static
                 else
                     op
                 end
            ClangParser.log.info "add function #{op.signature}"
            parent.add_operation(op)
            op
        rescue RuntimeError => e
            ClangParser.log.info "skipping instance method #{parent.full_name}::#{name}: #{e}"
            nil
        end

        # type_getter is also used for :result_type
        def process_parameter(cursor,parent,type_getter = :type)
            ClangParser.log.debug "process_parameter: spelling: '#{cursor.spelling}' type: '#{cursor.type}' kind '#{cursor.type.kind} parent #{parent}"
            para_name = cursor.spelling
            para_name = if para_name.empty?
                            "no_name_arg"
                        else
                            para_name
                        end
            default_value = nil
            type_cursor = nil
            template_name = ""
            name_space = []

            cursor.visit_children do |cu,_|
                ClangParser.log.info "process parameter: cursor kind: #{cu.kind} #{cu.expression}"
                case cu.kind
                when :integer_literal
                    exp = cu.expression
                    exp.pop
                    default_value = exp.join("")
                when :floating_literal
                    exp = cu.expression
                    exp.pop
                    default_value = exp.join("")
                when :call_expr
                    exp = cu.expression
                    exp.shift
                    exp.pop
                    default_value = exp.join("")
                when :gnu_null_expr
                    default_value = 0
                when :unexposed_expr
                    exp = cu.expression
                    exp.pop
                    default_value = exp.join("")
                when :template_ref
                    name_space << cu.spelling
                    if !template_name.empty?
                        template_name += "<#{name_space.join("::")}"
                    else
                        template_name = name_space.join("::")
                    end
                    name_space.clear
                when :namespace_ref
                    name_space << cu.spelling
                when :type_ref
                    type_cursor = cu
                when :compound_stmt
                when :parm_decl
                when :member_ref
                when :constant_array
                    exp = cu.expression
                    exp.pop
                    default_value = exp.gsub("{","[")
                    default_value = default_value.gsub("}","]")
                end
            end
            type = if template_name.empty?
                       type = if type_cursor
                                  to_rbind_type(parent,type_cursor)
                              end
                       # just upgrade type to pointer / ref if type != nil
                       to_rbind_type(parent,cursor,type,type_getter)
                   else
                       # parameter is a template type
                       # TODO find better way to get inner type
                       # we could use type_cursor here if given but this is 
                       # not the case for basic types and somehow the type 
                       # qualifier are not provided
                       expression = cursor.expression.join(" ")
                       inner_types = if expression =~ /<([ \w\*&,:]*)>/
                                         $1
                                     else
                                         raise RuntimeError,"Cannot parse template type parameter."
                                     end

                       inner_types = inner_types.split(",").map do |inner_type|
                           parent.type(inner_type)
                       end

                       templates = template_name.split("<")
                       templates << inner_types.map(&:full_name).join(",")

                       t = parent.type(templates.join("<")+">"*(templates.size-1),true)
                       to_rbind_type(parent,cursor,t,type_getter)
                   end
            RParameter.new(para_name,type,default_value)
        rescue RuntimeError => e
            raise ClangParserError.new(e.to_s,cursor)
        end

        def process_typedef(cu, parent)
            ClangParser.log.debug "process_typedef: #{cu}: expression: #{cu.expression} parent: #{parent}"
            exp = cu.expression.join(" ")

            # Remove typedef label and extract orig type and alias
            orig_and_alias = exp.sub("typedef","")
            orig_and_alias = orig_and_alias.sub(";","").strip
            orig_type = nil
            alias_type = nil

            if orig_and_alias =~ /(.*)\s+([^\s]+)/
                orig_type = $1
                alias_type = $2
            else
                raise RuntimeError,"Cannot parse typedef expression #{exp}"
            end

            begin
                t = parent.type(orig_type)
                ClangParser.log.debug "process_typedef: orig: '#{orig_type}' alias: #{alias_type}"
                parent.add_type_alias(t, alias_type)
            rescue RuntimeError => e
                ClangParser.log.warn "Cannot process typedef expression for orig: '#{orig_type}' alias: '#{alias_type}' : #{e}"
            end
            parent
        end

    end
end
