require 'yaml'

module Rbind
    class GeneratorExtern
        Config = Struct.new(:ruby_module_name)

        attr_accessor :output_path
        attr_accessor :ruby_module_name
        def self.normalize_type_name(name)
            name.gsub('::','.')
        end

        def initialize(root)
            @root = root
        end

        def generate(path = @output_path,ruby_module_name = @ruby_module_name)
            @output_path = path
            @ruby_module_name = ruby_module_name
            FileUtils.mkdir_p(path) if path && !File.directory?(path)
            file_extern = File.new(File.join(path,"extern.rbind"),"w")
            file_config = File.new(File.join(path,"config.rbind"),"w")

            @root.each_type do |t|
                if t.is_a? RClass
                    file_extern.write "class #{GeneratorExtern.normalize_type_name(t.full_name)} /Extern\n"
                elsif t.is_a? RStruct
                    file_extern.write "struct #{GeneratorExtern.normalize_type_name(t.full_name)} /Extern\n"
                end
            end

            @root.each_const do |c|
                file_extern.write "const #{GeneratorExtern.normalize_type_name(c.full_name)} /Extern\n"
            end
            file_extern.write("\n")
            file_config.write Config.new(ruby_module_name).to_yaml
        end
    end
end