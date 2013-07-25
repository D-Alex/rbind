
require 'rbind/clang/clang'
require 'rbind'
require 'pp'
require 'hooks'

module Rbind
    class ClangParser < RNamespace
        include Hooks
        extend ::Rbind::Logger

        define_hook :after_add_class

        def initialize
            super("root")
            self.root = true
            add_default_types
            add_std_types

            args = ["-xc++","-fno-rtti","-I/home/aduda/dev/rock1.9/install/include","-I/home/aduda/dev/rock1.9/install/include/opensfm"]
            clang = Clang::Clang.new
            tu = clang.translation_unit("/home/aduda/dev/rock1.9/temp/laser_line_filter.hpp",args)
            process_childs(tu.cursor)
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

        def process_namespace(cursor,parent)
            name = cursor.spelling
            ClangParser.log.info "processing namespace #{parent}::#{name}"
            parent.add_namespace(name)
        end

        def process_class(cursor,parent,default_access = :private)
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

            access = default_access
            cursor.visit_children do |cu,_|
                case cu.kind
                when :x_access_specifier
                    access = normalize_accessor(cu.cxx_access_specifier)
                when :x_base_specifier
                    access = normalize_accessor(cu.cxx_access_specifier)
                    p = parent.type(RBase.normalize(cu.spelling),false)
                    ClangParser.log.info "  auto add parent class #{cu.spelling}" unless p
                    p ||= parent.add_type(RClass.new(RBase.normalize(cu.spelling)))
                    klass.add_parent p,access
                when :field_decl
                when :constructor
                    puts "got constructor#{cu.spelling}"
                when :x_method
                    process_instance_method(cu,klass)
                end
            end

            #klass.flags = flags if flags
            #klass.extern_package_name = nil
            klass
        rescue RuntimeError  => e
            raise "input line #{cursor.location}: #{e}"
        end

        def process_instance_method(cursor,parent)
            name = cursor.spelling
            args = []

            result_type = cursor.result_type.declaration.spelling
            ClangParser.log.info "processing instance method #{result_type} #{parent}::#{name}"
            result_type = if result_type.empty?
                nil
            else
                parent.type(result_type)
            end

            cursor.visit_children() do |cu,_|
                obj = case cu.kind
                      when :parm_decl
                          para_name = cu.spelling
                          default_value = nil
                          type_name = []
                          name_space = []
                          template = 0
                          cu.visit_children(true) do |cu2,_|
                              case cu2.kind
                              when :integer_literal
                                  exp = cu2.expression
                                  exp.pop
                                  default_value = exp.join("")
                              when :floating_literal
                                  exp = cu2.expression
                                  exp.pop
                                  default_value = exp.join("")
                              when :call_expr
                                  exp = cu2.expression
                                  exp.shift
                                  exp.pop
                                  default_value = exp.join("")
                              when :unexposed_expr
                                  exp = cu2.expression
                                  exp.pop
                                  default_value = exp.join("")
                              when :template_ref
                                  name_space << cu2.spelling
                                  if template > 0
                                      # normalize differently if this is a template
                                      t = type_name.pop
                                      type_name << "#{t}<#{name_space.join("::")}"
                                  else
                                      type_name += name_space
                                  end
                                  name_space.clear
                                  template += 1
                              when :namespace_ref
                                  name_space << cu2.spelling
                              when :type_ref
                                  # normalize name
                                  # sometimes namespace is given explicitly
                                  #
                                  # remove struct, class etc and split
                                  names = cu2.spelling.split(" ").last.split("::")
                                  # get type name
                                  name = names.pop
                                  #puts cu2.type.canonical_type.declaration.spelling

                                  # genreate namespace
                                  names.each_with_index do |n,i|
                                      if name_space[i] != n
                                          name_space += names[i..-1]
                                          break
                                      end
                                  end
                                  # add type name to namespace
                                  name_space << name
                                  if template > 0
                                      # normalize differently if this is a template
                                      t = type_name.pop
                                      type_name << "#{t}<#{name_space.join("::")}"+">"*template
                                  else
                                      type_name += name_space
                                  end
                                  name_space.clear
                                  template = 0
                              end
                          end
                          type_name = if cu.type.pod?
                                          cu.type.canonical_type.kind.to_s
                                      elsif template > 0
                                          # template was not parsed correctly
                                          # this happens for example for std::vector<int>
                                          cursor.expression.join() =~ /.*<(\w*)>.*/
                                          type_name.join("::") + "<#{$1}" +">"*template
                                      else
                                         type_name.join("::") + ">"*template
                                      end
                          ClangParser.log.info "  add parameter #{type_name} #{para_name} #{default_value ? " = #{default_value}" : nil}"
                          type = parent.type(type_name)
                          args << RParameter.new(para_name,type,default_value,:IO)
                      end
            end
            op = ::Rbind::ROperation.new(name,result_type,*args)
            parent.add_operation(op)
        end

        def process_childs(cursor,parent = self)
            cursor.visit_children(false) do |cu,_|
                obj = case cu.kind
                      when :namespace
                          process_namespace(cu,parent)
                      when :enum_decl
                          puts "got enum declaration #{cu.spelling}"
                      when :union_decl
                          puts "got union declaration #{cu.spelling}"
                      when :struct_decl
                          puts "got struct declaration #{cu.spelling}"
                      when :class_decl
                          process_class(cu,parent)
                      when :function_decl
                          puts "got function decl #{cu.spelling}"
                      when :macro_expansion # CV_WRAP ...
                          puts "got macro #{cu.spelling}"
                      end
                process_childs(cu,obj || parent)
#                            puts "#{cu.kind} #{cu.spelling}"
            end
        end
    end
end

Rbind::ClangParser.new
