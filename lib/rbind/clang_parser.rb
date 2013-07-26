
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
            add_std_types
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
        def to_rbind_type(parent,type_cursor,rbind_type=nil)
            clang_type = type_cursor.type.canonical_type
            clang_type,level = pointee_type(clang_type)

            # generate rbind type
            clang_type = clang_type.canonical_type
            t = if rbind_type
                    rbind_type
                elsif clang_type.pod? && clang_type.kind != :record && clang_type.kind
                    parent.type(clang_type.kind.to_s)
                else
                    parent.type(clang_type.declaration.spelling)
                end

            # add pointer level
            1.upto(level) do
                t = t.to_ptr
            end
            t = if clang_type.kind == :l_value_reference
                    t.to_ref
                else
                    t
                end
        end

        # entry call to parse a file
        def process(cursor,parent = self)
            cursor.visit_children(false) do |cu,_|
                case cu.kind
                when :namespace
                    process_namespace(cu,parent)
                when :enum_decl
                    puts "got enum declaration #{cu.spelling}"
                when :union_decl
                    puts "got union declaration #{cu.spelling}"
                when :struct_decl
                    process_class(cu,parent)
                when :class_decl
                    process_class(cu,parent)
                when :function_decl
                    puts "got function decl #{cu.spelling}"
                when :macro_expansion # CV_WRAP ...
                    puts "got macro #{cu.spelling} #{cu.location}"
                when :class_template
                    process_class_template(cu,parent)
                when :x_access_specifier
                    access = normalize_accessor(cu.cxx_access_specifier)
                when :x_base_specifier
                    access = normalize_accessor(cu.cxx_access_specifier)
                    p = parent.type(RBase.normalize(cu.spelling),false)
                    ClangParser.log.info "auto add parent class #{cu.spelling}" unless p
                    p ||= parent.add_type(RClass.new(RBase.normalize(cu.spelling)))
                    parent.add_parent p,access
                when :field_decl
                when :constructor
                    puts "got constructor#{cu.spelling}"
                when :x_method
                    process_instance_method(cu,parent)
                end
                #puts "#{cu.kind} #{cu.spelling}"
            end
        end

        def process_namespace(cursor,parent)
            name = cursor.spelling
            ClangParser.log.info "processing namespace #{parent}::#{name}"
            ns = parent.add_namespace(name)
            process(cursor,ns)
        end

        #TODO not implemented
        def process_class_template(cursor,parent,default_access = :private)
            class_name = cursor.spelling
            ClangParser.log.info "processing class template #{parent}::#{class_name}"
            cursor.visit_children do |cu,_|
                puts "#{cu.kind} #{cu.spelling}"
            end
        end

        def process_class(cursor,parent)
            class_name = cursor.spelling
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

        def process_instance_method(cursor,parent)
            name = cursor.spelling
            args = []

            result_type = cursor.result_type.declaration.spelling
            result_type = if result_type.empty?
                              nil
                          else
                              parent.type(result_type)
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
            expression = cursor.expression.join()
            args.each do |arg|
                if(!arg.default_value && (expression =~ /#{arg.name}=(\w*)/))
                    arg.default_value = $1
                end
            end
            op = ::Rbind::ROperation.new(name,result_type,*args)
            ClangParser.log.info "add opeartion #{parent.full_name}::#{op.signature}"
            parent.add_operation(op)
        end
        
        def process_parameter(cursor,parent)
            para_name = cursor.spelling
            default_value = nil
            type_cursor = nil
            template_name = ""
            name_space = []
            cursor.visit_children(true) do |cu,_|
                #puts "#{cu.kind} #{cu.spelling} #{cu.expression}"
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
                       to_rbind_type(parent,cursor,type)
                   else
                       # parameter is a template type
                       # TODO find better way to get inner type
                       expression = cursor.expression.join(" ")
                       inner_type = if expression =~ /<([ \w\*&]*)>/
                                        $1
                                    else
                                        raise RuntimeError,"Cannot parse template type"
                                    end
                       pointer_level = inner_type.count("*")
                       ref_level = inner_type.count("&")
                       const = inner_type.count("const")
                       inner_type = inner_type.gsub("*","").gsub("&","").gsub("const ","").gsub("unsigned ","u").gsub(" ","")
                       type = if type_cursor
                                  to_rbind_type(parent,type_cursor)
                              else
                                  parent.type(inner_type)
                              end
                       1.upto(pointer_level) do
                           type = type.to_ptr
                       end
                       1.upto(ref_level) do
                           type = type.to_ref
                       end

                       templates = template_name.split("<")
                       templates << type.full_name

                       t = parent.type(templates.join("<")+">"*(templates.size-1),false)
                       t ||= begin
                                 #TODO parse specialization of the template ?
                                 parent.type(templates.join("<")+">"*(templates.size-1))
                             end
                       to_rbind_type(parent,cursor,t)
                   end
            RParameter.new(para_name,type,default_value,:IO)
        rescue RuntimeError => e
            raise ClangParserError.new(e.to_s,cursor)
        end

    end
end
