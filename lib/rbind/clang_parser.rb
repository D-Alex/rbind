
require 'rbind/clang/clang'
require 'rbind'
require 'pp'
require 'hooks'

module Rbind
    class ClangParser < RNamespace
        class ClangParserError < RuntimeError
            def initialize(message,cursor=nil)
                @cursor = cursor
                super(message)
            end

            def to_s
                @cursor.location.join(":") + ": " + @cursor.expression.to_s + super
            end
        end

        include Hooks
        extend ::Rbind::Logger

        def initialize(args = ["-xc++","-fno-rtti"])
            super("root")
            self.root = true
            add_default_types
            add_type(StdVector.new("std::vector"))
            @clang = Clang::Clang.new
        end

        def parse(file_path,args = ["-xc++","-fno-rtti"])
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
        def to_rbind_type(parent,cursor,rbind_type=nil,type_getter = :type)
            clang_type = cursor.send(type_getter)
            return nil if clang_type.null?
            clang_type = clang_type.canonical_type
            clang_type,level = pointee_type(clang_type)

            # generate rbind type
            clang_type = clang_type.canonical_type
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
                               name
                           end
                    parent.type(name)
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
        def process(cursor,parent = self)
            cursor.visit_children(false) do |cu,_|
             #   puts "----->#{cu.kind} #{cu.spelling} #{cu.type.kind} #{cu.specialized_template.kind}"
                case cu.kind
                when :namespace
                    process_namespace(cu,parent)
                when :enum_decl
                    process_enum(cu,parent)
                when :union_decl
            #        puts "got union declaration #{cu.spelling}"
                when :struct_decl
                    process_class(cu,parent)
                when :class_decl
                    process_class(cu,parent)
                when :function_decl
                    process_function(cu,parent)
                when :macro_expansion # CV_WRAP ...
         #           puts "got macro #{cu.spelling} #{cu.location}"
                when :function_template
            #        puts "got template fuction #{cu.spelling} #{cu.location}"
                when :class_template
                    process_class_template(cu,parent)
                when :template_type_parameter
                    parent.add_type(RTemplateParameter.new(cu.spelling))
                when :x_access_specifier
                    access = normalize_accessor(cu.cxx_access_specifier)
                when :x_base_specifier
                    access = normalize_accessor(cu.cxx_access_specifier)
                    p = parent.type(RBase.normalize(cu.spelling),false)
                    ClangParser.log.info "auto add parent class #{cu.spelling}" unless p
                    p ||= parent.add_type(RClass.new(RBase.normalize(cu.spelling)))
                    parent.add_parent p,access
                when :field_decl
                    process_field(cu,parent)
                when :constructor
                    process_function(cu,parent)
                when :x_method
                    process_function(cu,parent)
                when :typedef_decl
                    # rename object if parent has no name
                    if parent.name == "unknown"
                        puts "rename #{parent.full_name} to #{cu.spelling}: #{cu.location}"
                    end
                when :var_decl
                    process_variable(cu,parent)
                else
                    #puts "skip: #{cu.spelling}"
                end
            end
        end

        def process_namespace(cursor,parent)
            name = cursor.spelling
            ClangParser.log.info "processing namespace #{parent}::#{name}"
            ns = parent.add_namespace(name)
            process(cursor,ns)
        end

        def process_enum(cursor,parent)
            name = cursor.spelling
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
        end

        def process_field(cursor,parent)
            name = cursor.spelling
            ClangParser.log.info "processing field #{parent}::#{name}"
            var =  process_parameter(cursor,parent)
            # TODO write flag
            attr = RAttribute.new(var.name,var.type)
            parent.add_attribute attr
            attr
        end

        def process_class_template(cursor,parent,default_access = :private)
            class_name = cursor.spelling
            ClangParser.log.info "processing class template #{parent}::#{class_name}"

            klass = parent.type(class_name,false)
            klass = if(!klass)
                        klass = RTemplateClass.new(class_name)
                        parent.add_type(klass)
                        klass
                    else
                        if klass.empty? && !klass.template?
                            ClangParser.log.info " reopening existing class template #{klass}"
                            klass
                        else
                            raise "Cannot reopening existing class #{klass} which is non-empty!"
                        end
                    end
            process(cursor,klass)
        end

        def process_class(cursor,parent)
            class_name = cursor.spelling
            class_name = if class_name.empty?
                             "unknown"
                         else
                             class_name
                         end
            ClangParser.log.info "processing class #{parent}::#{class_name}"

            klass = parent.type(class_name,false)
            klass = if(!klass)
                        klass = RClass.new(class_name)
                        parent.add_type(klass)
                        klass
                    else
                        if klass.empty?
                            ClangParser.log.info " reopening existing class #{klass}"
                            klass
                        else
                            raise "Cannot reopening existing class #{klass} which has is non-empty!"
                        end
                    end
            #klass.flags = flags if flags
            #klass.extern_package_name = nil
            process(cursor,klass)
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
                if(!arg.default_value && (expression =~ /#{arg.name}=(\w*)/))
                    arg.default_value = $1
                end
                arg.name = if(arg.name == "unknown")
                               arg.name + idx.to_s
                           else
                               arg.name
                           end
            end

            result_type = if !cursor.result_type.null?
                              process_parameter(cursor,parent,:result_type).type
                          end
            op = ::Rbind::ROperation.new(name,result_type,*args)
            ClangParser.log.info "add function #{op.signature}"
            parent.add_operation(op)
        rescue RuntimeError => e
            ClangParser.log.info "skipping instance method #{parent.full_name}::#{name}: #{e}"
        end
        
        # type_getter is also used for :result_type
        def process_parameter(cursor,parent,type_getter = :type)
            para_name = cursor.spelling
            para_name = if para_name.empty?
                            "unknown"
                        else
                            para_name
                        end
            default_value = nil
            type_cursor = nil
            template_name = ""
            name_space = []

            cursor.visit_children do |cu,_|
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
                       inner_types = if expression =~ /<([ \w\*&,]*)>/
                                        $1
                                    else
                                        raise RuntimeError,"Cannot parse template type"
                                    end

                       inner_types = inner_types.split(",").map do |inner_type|
                           parent.type(inner_type)
                       end

                       templates = template_name.split("<")
                       templates << inner_types.map(&:full_name).join(",")

                       t = parent.type(templates.join("<")+">"*(templates.size-1),true)
                       to_rbind_type(parent,cursor,t,type_getter)
                   end
            RParameter.new(para_name,type,default_value,:IO)
        rescue RuntimeError => e
            raise ClangParserError.new(e.to_s,cursor)
        end
    end
end
