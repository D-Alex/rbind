require 'fileutils'
require 'delegate'
require 'erb'

module Rbind
    class GeneratorRuby
        def self.keyword?(name)
            %w{__FILE__ __LINE__ alias and begin BEGIN break case class def defined? do else elsif end END ensure false for if in module next nil not or redo rescue retry return self super then true undef unless until when while yield}.include? name
        end

        def self.normalize_arg_name(name)
            name = name.to_s.sub(/\A#{RBase.cprefix}?/, "").gsub(/(?<!\A)\p{Lu}/u, '_\0').downcase
            name = if keyword?(name)
                       "#{name}_"
                   else
                       name
                   end
            # check for digits at the beginning
            if name =~/\d(.*)/
                "_#{name}"
            else
                name
            end
        end

        def self.normalize_default_value(parameter)
            return nil unless parameter.default_value
            val = if parameter.type.basic_type? || parameter.type.ptr?
                      if parameter.type.name == "float"
                          parameter.default_value.gsub("f","")
                      elsif parameter.type.name == "double"
                          parameter.default_value.gsub(/\.$/,".0")
                      else
                          normalize_type_name(parameter.default_value)
                      end
                  else
                      if(parameter.default_value =~ /(\w*)\((.*)\)/)
                          t = parameter.owner.owner.type($1,false)
                          if t
                              "#{normalize_type_name(t.full_name)}.new(#{$2})"
                          else
                              ns = RBase.namespace($1)
                              t = parameter.owner.owner.type(ns,false) if ns
                              ops = Array(t.operation($1,false)) if t
                              "#{normalize_method_name(ops.first.full_name)}(#{$2})" if ops && !ops.empy?
                          end
                      else
                          parameter.default_value
                      end
                  end
            if val
                val
            else
               raise "cannot parse default parameter value #{parameter.default_value} for #{parameter.owner.signature}"
            end
        end


        def self.normalize_type_name(name)
            name.split("::").map do |n|
                n.gsub(/^(\w)(.*)/) do 
                    $1.upcase+$2
                end
            end.join("::")
        end

        def self.normalize_basic_type_name(name)
            @@basic_type_map ||= {"char *" => "string","unsigned char" => "uchar" ,"const char *" => "string" }
            n = @@basic_type_map[name]
            n ||= name
            if n =~ /\*/
                "pointer"
            else
                n
            end
        end

        def self.normalize_method_name(name)
            name = name.to_s.sub(/\A#{RBase.cprefix}?/, "").gsub(/(?<!\A)\p{Lu}/u, '_\0').downcase
            str = ""
            name.split("_").each_with_index do |n,i|
                if n.empty?
                    str += "_"
                    next
                end
                if n.size == 1 && i > 1
                    str += n
                else
                    str += "_#{n}"
                end
            end
            name = str[1,str.size-1]
            name = if name =~/^operator(.*)/
                        n = $1
                        if n =~ /\(\)/
                            raise "forbbiden method name #{name}"
                        elsif n=~ /(.*)(\d)/
                            if $1 == "[]"
                                "array_operator#{$2}"
                            elsif $1 == "+"
                                "plus_operator#{$2}"
                            elsif $1 == "-"
                                "minus_operator#{$2}"
                            elsif $1 == "*"
                                "mul_operator#{$2}"
                            elsif $1 == "/"
                                "div_operator#{$2}"
                            else
                                raise "forbbiden method name #{name}"
                            end
                        else
                            n
                        end
                   else
                        name
                   end
        end

        class HelperBase
            attr_accessor :name
            def initialize(name,root)
                @name = name.to_s
                @root = root
            end

            def full_name
                @root.full_name
            end

            def binding
                Kernel.binding
            end
        end

        class RBindHelper < HelperBase
            #TODO
            attr_accessor :library_name

            def initialize(name, root)
                super
            end

            def normalize_t(name)
                GeneratorRuby.normalize_type_name name
            end

            def normalize_bt(name)
                GeneratorRuby.normalize_basic_type_name name
            end

            def normalize_m(name)
                GeneratorRuby.normalize_method_name name
            end

            def add_accessors
                str = ""
                @root.each_type do |t|
                    next if t.basic_type? && !t.is_a?(RNamespace)
                    str += "\n#methods for #{t.full_name}\n"
                    if t.cdelete_method
                        str += "attach_function :#{normalize_m t.cdelete_method},"\
                        ":#{t.cdelete_method},[#{normalize_t t.full_name}],:void\n"
                        str += "attach_function :#{normalize_m t.cdelete_method}_struct,"\
                        ":#{t.cdelete_method},[#{normalize_t t.full_name}Struct],:void\n"
                    end
                    str += t.operations.map do |ops|
                        ops.map do |op|
                            return_type = if op.constructor?
                                              "#{normalize_t op.owner.full_name}"
                                          else
                                              if op.return_type.basic_type?
                                                  ":#{normalize_bt op.return_type.csignature}"
                                              else
                                                  "#{normalize_t op.return_type.full_name}"
                                              end
                                          end
                            args = op.cparameters.map do |p|
                                if p.type.basic_type?
                                    ":#{normalize_bt p.type.csignature}"
                                else
                                    "#{normalize_t p.type.full_name}"
                                end
                            end
                            fct_name = normalize_m op.cname
                            "attach_function :#{fct_name},:#{op.cname},[#{args.join(",")}],#{return_type}\n"
                        end.join
                    end.join
                    str+"\n"
                end
                str+"\n"
                str.gsub(/\n/,"\n        ")
            end
        end

        class RTypeHelper < HelperBase
            class OperationHelper < SimpleDelegator
                def wrap_parameters_signature
                    parameters.map do |p|
                        n = GeneratorRuby.normalize_arg_name p.name
                        if p.default_value 
                            "#{n} = #{GeneratorRuby.normalize_default_value p}"
                        else
                            n
                        end
                    end.join(", ")
                rescue RuntimeError
                    ::Rbind.log.warn "ignoring all default parameter values for #{full_name} because of missing definitions."
                    parameters.map do |p|
                        GeneratorRuby.normalize_arg_name p.name
                    end.join(", ")
                end

                def wrap_parameters_call
                    paras = []
                    paras << "self" if instance_method?
                    paras += parameters.map do |p|
                        GeneratorRuby.normalize_arg_name p.name
                    end
                    paras.join(", ")
                end

                def name
                    if attribute?
                        name = GeneratorRuby.normalize_method_name(attribute.name)
                        if __getobj__.is_a? RGetter
                            name
                        else
                            "#{name}="
                        end
                    else
                        GeneratorRuby.normalize_method_name(__getobj__.alias || __getobj__.name)
                    end
                end

                def cname
                    GeneratorRuby.normalize_method_name(__getobj__.cname)
                end

                def binding
                    Kernel.binding
                end
            end

            def initialize(name, root)
                @type_wrapper = ERB.new(File.open(File.join(File.dirname(__FILE__),"templates","ruby","rtype.rb")).read,nil,"-")
                @type_constructor_wrapper = ERB.new(File.open(File.join(File.dirname(__FILE__),"templates","ruby","rtype_constructor.rb")).read,nil,"-")
                @namespace_wrapper = ERB.new(File.open(File.join(File.dirname(__FILE__),"templates","ruby","rnamespace.rb")).read,nil,"-")
                @static_method_wrapper = ERB.new(File.open(File.join(File.dirname(__FILE__),"templates","ruby","rstatic_method.rb")).read)
                @method_wrapper = ERB.new(File.open(File.join(File.dirname(__FILE__),"templates","ruby","rmethod.rb")).read,nil,'-')
                super
            end

            def name
                GeneratorRuby.normalize_type_name(@name)
            end

            def cname
                GeneratorRuby.normalize_type_name(@root.cname)
            end

            def cdelete_method
                GeneratorRuby.normalize_method_name(@root.cdelete_method)
            end

            def add_specializing
                if @root.respond_to?(:specialize_ruby)
                    @root.specialize_ruby
                else
                    nil
                end
            end

            def add_constructor
                raise "there is no constructor for namespaces!" if self.is_a?(RNamespace)
                ops = Array(@root.operation(@root.name,false))
                return until ops
                ops.map do |c|
                    ch = OperationHelper.new(c)
                    @type_constructor_wrapper.result(ch.binding)
                end.join("\n")
            end

            def add_consts
                @root.consts.map do |c|
                    "    #{c.name} = #{GeneratorRuby::normalize_type_name(c.value)}\n"
                end.join
            end

            def add_methods
                str = ""
                @root.operations.each do |ops|
                    ops.each do |op|
                        next if op.constructor?
                        oph = OperationHelper.new(op)
                        str += if op.instance_method?
                                   @method_wrapper.result(oph.binding)
                               else
                                   @static_method_wrapper.result(oph.binding)
                               end
                    end
                end
                str
            end

            def add_types
                str = ""
                @root.each_type(false) do |t|
                    next if t.basic_type? && !t.is_a?(RNamespace)
                    t = RTypeHelper.new(t.name,t)
                    str += t.result
                end
                str
            end

            def full_name
                @root.full_name
            end

            def result
                str = if @root.is_a? RStruct
                          @type_wrapper.result(self.binding)
                      else
                          @namespace_wrapper.result(self.binding)
                      end
                if(@root.root?)
                    str
                else
                    str.gsub!("\n","\n    ").gsub!("    \n","\n")
                    "    "+str[0,str.size-4]
                end
            end
        end

        attr_accessor :module_name
        attr_accessor :library_name
        attr_accessor :output_path


        def initialize(root,module_name ="Rbind",library_name="rbind_lib")
            @root = root
            @rbind_wrapper = ERB.new(File.open(File.join(File.dirname(__FILE__),"templates","ruby","rbind.rb")).read)
            @module_name = module_name
            @library_name = library_name
        end

        def generate(path=@output_path)
            @output_path = path
            FileUtils.mkdir_p(path) if path  && !File.directory?(path)
            file_rbind = File.new(File.join(path,"opencv.rb"),"w")
            file_types = File.new(File.join(path,"opencv_types.rb"),"w")

            types = RTypeHelper.new(@module_name,@root)
            file_types.write types.result
            rbind = RBindHelper.new(@module_name,@root)
            rbind.library_name = @library_name
            file_rbind.write @rbind_wrapper.result(rbind.binding)
        end
    end
end
