require 'open3'

module Rbind
    class Rbind
        attr_reader :parser
        attr_reader :generator_c
        attr_reader :generator_ruby
        attr_accessor :includes
        attr_accessor :name
        attr_accessor :pkg_config
        attr_accessor :gems

        def self.pkg_paths(pkg_name)
            out = IO.popen("pkg-config --cflags-only-I #{pkg_name}")
            paths = out.read.split("-I").delete_if(&:empty?).map do |i|
                i.gsub("\n","").gsub(" ","")
            end
            raise "Cannot find pkg paths for #{pkg_name}" if paths.empty?
            paths
        end

        def self.rbind_pkgs(pkg_names)
            pkg_names.find_all do |p|
                !!(p =~ /^rbind_.*/)
            end
        end

        def self.gem_path(gem_name)
            # TODO use gem api
            out = IO.popen("gem contents #{gem_name}")
            out.readlines.each do |line|
                return $1 if line =~ /(.*)extern.rbind/
            end
            raise "Cannot find paths for gem #{gem_name}"
        end

        def self.rbind_pkg_paths(pkg_names)
            rbind_packages = rbind_pkgs(pkg_names)
            rbind_paths = rbind_packages.map do |pkg|
                paths = pkg_paths(pkg)
                path = paths.find do |p|
                    File.exist?(File.join(p,pkg,"extern.rbind"))
                end
                raise "cannot find extern.rbind for rbind package #{pkg}" unless path
                File.join(path,pkg)
            end
        end

        def initialize(name,parser = DefaultParser.new)
            @name = name
            @includes = []
            @pkg_config = []
            @gems = []
            @parser = parser
            lib_name = "rbind_#{name.downcase}"
            @generator_c = GeneratorC.new(@parser,lib_name)
            @generator_ruby = GeneratorRuby.new(@parser,name,lib_name)
            @generator_extern = GeneratorExtern.new(@parser)
        end

        def parse(*files)
            files.flatten.each do |path|
                parser.parse path
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

        # parses other rbind packages
        def parse_extern
            # extern package are always paresed with the default parser 
            local_parser = DefaultParser.new(parser)
            paths = Rbind.rbind_pkg_paths(@pkg_config)
            paths.each do |pkg|
                config = YAML.load(File.open(File.join(pkg,"config.rbind")).read)
                path = File.join(pkg,"extern.rbind")
                ::Rbind.log.info "parsing extern rbind pkg file #{path}"
                raise "no module name found" if !config.ruby_module_name || config.ruby_module_name.empty?
                local_parser.parse(File.open(path).read,config.ruby_module_name)
            end
            @gems.each do |gem|
                path = Rbind.gem_path(gem)
                config = YAML.load(File.open(File.join(path,"config.rbind")).read)
                path = File.join(path,"extern.rbind")
                ::Rbind.log.info "parsing extern gem file #{path}"
                local_parser.parse(File.open(path).read,config.ruby_module_name)
            end
            self
        end

        def parse_headers_dry(*headers)
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
            out.read
        end

        def parse_headers(*headers)
            parser.parse parse_headers_dry(*headers)
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
            generate_extern c_path
            generate_ruby ruby_path
        end

        def generate_ruby(path)
            ::Rbind.log.info "generate ruby ffi wrappers"
            paths = Rbind.rbind_pkg_paths(@pkg_config)
            modules = paths.map do |pkg|
                config = YAML.load(File.open(File.join(pkg,"config.rbind")).read)
                config.file_prefix
            end
            @generator_ruby.required_module_names = modules + gems
            @generator_ruby.generate(path)
        end

        def generate_c(path)
            ::Rbind.log.info "generate c wrappers"
            @generator_c.includes += includes
            @generator_c.includes.uniq!
            @generator_c.pkg_config = pkg_config
            @generator_c.gems = gems
            @generator_c.generate(path)
        end

        def generate_extern(path)
            @generator_extern.generate(path,@generator_ruby.module_name,@generator_ruby.file_prefix)
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

        def libs
            @generator_c.libs
        end

        def add_std_string
            @generator_c.includes << "<string>"
            @parser.add_type(StdString.new("std::string",@parser))
            @parser.type_alias["basic_string"] = @parser.std.string
            self
        end

        def add_std_vector
            @generator_c.includes << "<vector>"
            @parser.add_type(StdVector.new("std::vector"))
            self
        end

        def add_std_map
            @generator_c.includes << "<map>"
            @parser.add_type(StdMap.new("std::map"))
        end
        def add_std_types
            add_std_vector
            add_std_string
            add_std_map
        end

        def method_missing(m,*args)
            t = @parser.type(m.to_s,false,false)
            return t if t

            op = @parser.operation(m.to_s,false)
            return op if op

            super
        end
    end
end
