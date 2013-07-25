
require 'rbind/clang/clang'
require 'rbind'
require 'pp'
require 'hooks'

module Rbind
    class ClangParser < RNamespace
        include Hooks
        extend ::Rbind::Logger

        define_hook :find_type
        define_hook :add_class

        def initialize
            super("root")
            self.root = true
            add_default_types

            args = ["-xc++","-fno-rtti","-I/home/aduda/dev/rock1.9/install/include","-I/home/aduda/dev/rock1.9/install/include/opensfm"]
            clang = Clang::Clang.new
            tu = clang.translation_unit("/home/aduda/dev/rock1.9/temp/laser_line_filter.hpp",args)
            @object_stack = []
            process_childs(tu.cursor)
        end

        def current_obj
            obj = @object_stack.last
            obj ||= self
        end

        def process_namespace(cursor,parent)
            puts "got namespace #{cursor.spelling}, parent = #{parent.spelling}"
        end

        def process_class(cursor,parent)
            class_name = cursor.spelling
            owner = current_obj
            ClangParser.log.info "processing class #{class_name}, parent = #{parent.spelling}"
            t = RClass.new(class_name)
            access = :x_private

            cursor.visit_children do |cu,parent|
                case cu.kind
                when :x_access_specifier
                    access = cu.cxx_access_specifier
                when :x_base_specifier
                    if :x_public == cu.cxx_access_specifier
                        p = owner.type(RBase.normalize(cu.spelling),false)
                        ClangParser.log.info "  auto add parent class #{name}" unless p
                        p ||= owner.add_type(RClass.new(RBase.normalize(cu.spelling)))
                        t.add_parent p
                    else
                        ClangParser.log.info "  ignore none public parent #{cu.spelling}"
                    end
                when :field_decl
                    if :x_public == access
                    else
                        ClangParser.log.info "  ignore none public field #{cu.spelling}"
                    end
                when :constructor
                    puts "got constructor#{cu.spelling}, parent = #{parent.spelling}"
                when :x_method
                    if :x_public == access
                        puts "got c++ function decl #{cu.spelling}, parent = #{parent.spelling}"
                    #   process_instance_method(cu,parent)
                    else
                        ClangParser.log.info "  ignore none public method #{cu.spelling}"
                    end
                end
            end

            t = if t2 = owner.type(t.full_name,false)
                    if !t2.is_a?(RClass) || (!t2.parent_classes.empty? && t2.parent_classes != t.parent_classes)
                        raise "Cannot add class #{t.full_name}. A different type #{t2} is already registered"
                    else
                        t.parent_classes.each do |p|
                            t2.add_parent p
                        end
                        #TODO add methods and all the stuff
                        t2
                    end
                else
                    owner.add_type(t)
                    t
                end
            #t.flags = flags if flags
            #t.extern_package_name = nil
            t
        rescue RuntimeError  => e
            raise "input line #{cursor.location}: #{e}"
        end

        def process_instance_method(cursor,parent)
            puts "got c++ function decl #{cursor.spelling}, parent = #{parent.spelling}"
            cursor.visit_children() do |cu,parent|
                obj = case cu.kind
                      when :parm_decl
                          puts "  got para name #{cu.spelling}, parent = #{parent.spelling}"
                          cu.visit_children() do |cu2,parent2|
                              case cu2.kind
                              when :integer_literal
                                  pp cu2.expression
                                  puts "     got default value #{cu2.spelling}, #{cu2.display_name}"
                              when :floating_literal
                                  pp cu2.expression
                                  puts "     got default value #{cu2.spelling}, #{cu2.display_name}"
                              when :unexposed_expr
                                  pp cu2.expression
                              when :template_ref
                                  puts "  got template ref #{cu2.spelling}, parent = #{parent2.spelling}"
                              when :namespace_ref
                                  puts "  got namepsace ref #{cu2.spelling}, parent = #{parent2.spelling}"
                              when :call_expr
                                  pp cu2.expression
                              when :type_ref
                                  puts "  got type ref #{cu2.spelling}, parent = #{parent2.spelling}"
                              end
                          end
                      end
            end
        end

        def process_childs(cursor)
            cursor.visit_children(false) do |cu,parent|
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
                          puts "got function decl #{cu.spelling}, parent = #{parent.spelling}"
                      when :macro_expansion # CV_WRAP ...
                          puts "got macro #{cu.spelling}, parent = #{parent.spelling}"
                      end

                if !cu.null?
                    # push current object
                    @object_stack << obj if obj
                    process_childs(cu)
                    # pop current object
                    @object_stack.pop if obj
                end
#                            puts "#{cu.kind} #{cu.spelling}"
            end
        end
    end
end

Rbind::ClangParser.new
