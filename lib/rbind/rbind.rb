require 'open3'

module Rbind
    class Rbind
        attr_accessor :parser
        attr_accessor :generator_c
        attr_accessor :generator_ruby
        attr_accessor :includes
        attr_accessor :name
        attr_accessor :pkg_config

        def initialize(name)
            @name = name
            @includes = []
            @pkg_config = []
            @parser = DefaultParser.new
            lib_name = "rbind_#{name.downcase}"
            @generator_c = GeneratorC.new(@parser,lib_name)
            @generator_ruby = GeneratorRuby.new(@parser,name,lib_name)
        end

        def parse(*files)
            files.each do |path|
                parser.parse File.new(path).read
            end
        end

        def check_python
            out = IO.popen("which python")
            if(out.read.empty?)
                raise 'Cannot find python interpreter needed for parsing header files'
            end
            in_,out,err = Open3.popen3("python --version")
            str = err.read
            str = if str.empty?
                      out.read
                  else
                      str
                  end
            if(str =~ /[a-zA-Z]* (.*)/)
                if $1.to_f < 2.7
                    raise "Wrong python version #{$1}. At least python 2.7 is needed for parsing header files"
                end
            else
                raise 'Cannot determine python version needed for parsing header files'
            end
        end

        def parse_headers(*headers)
            ::Rbind.log.info "parse header files"
            check_python
            headers = if headers.empty?
                          includes
                      else
                          headers
                      end
            headers = headers.map do |h|
                "\"#{h}\""
            end
            path = File.join(File.dirname(__FILE__),'tools','hdr_parser.py')
            out = IO.popen("python #{path} #{headers.join(" ")}")
            parser.parse out.read
        end

        def build
            ::Rbind.log.info "build c wrappers"
            path = File.join(generator_c.output_path,"build")
            FileUtils.mkdir_p(path) if path && !File.directory?(path)
            Dir.chdir(path) do
                if !system("cmake -C ..")
                    raise "CMake Configure Error"
                end
                if !system("make")
                    raise "Make Build Error"
                end
            end
            if !system("cp #{File.join(path,"lib*.*")} #{generator_ruby.output_path}")
                raise "cannot copy library to #{generator_ruby.output_path}"
            end
            ::Rbind.log.info "all done !"
        end

        def generate(c_path = "src",ruby_path = "ruby/lib/#{name.downcase}")
            generate_c c_path
            generate_ruby ruby_path
        end

        def generate_ruby(path)
            ::Rbind.log.info "generate ruby ffi wrappers"
            @generator_ruby.generate(path)
        end

        def generate_c(path)
            ::Rbind.log.info "generate c wrappers"
            @generator_c.includes = includes
            @generator_c.pkg_config = pkg_config
            @generator_c.generate(path)
        end

        def use_namespace(name)
            t = if name.is_a? String
                    parser.type(name)
                else
                    name
                end
            parser.use_namespace t
        end

        def type(*args)
            parser.type(*args)
        end

        def on_type_not_found(&block)
            @parser.on_type_not_found(&block)
        end

        def method_missing(m,*args)
            t = @parser.type(m.to_s,false)
            return t if t

            op = @parser.operation(m.to_s,false)
            return op if op

            super
        end
    end
end
