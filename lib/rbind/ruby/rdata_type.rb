
module Rbind
    module Ruby
        class RDataType < DelegateClass(RDataType)
            include Hooks
            define_hook :on_normalize_name

            class << self
                attr_accessor :ffi_type_map
                def normalize_name_ffi(name)
                    n = ffi_type_map[name]
                    n ||= name
                    if n =~ /\*/ || n =~ /&/
                        "pointer"
                    else
                        n
                    end
                end

                def normalize_name(name)
                    if self.callbacks_for_hook(:on_normalize_name)
                        results = self.run_hook(:on_normalize_name,name)
                        results.compact!
                        return results.first unless results.empty?
                    end
                    name.gsub!(" ","")

                    # Parse constant declaration with suffix like 1000000LL
                    if name =~ /^([0-9]+)[uUlL]{0,2}/
                        name = $1
                        return name
                    end

                    # map template classes
                    # std::vector<std::string> -> Std::Vector::Std_String
                    if name =~ /([\w:]*)<(.*)>$/
                        return "#{normalize_type_name($1)}::#{normalize_type_name($2).gsub("::","_")}"
                    else
                        name
                    end

                    # map all uint ... to Fixnum
                    if name =~ /^u?int\d*$/ || name =~ /^u?int\d+_t$/
                        return "Fixnum"
                    end

                    name = name.gsub(/^_/,"")
                    names = name.split("::").map do |n|
                        n.gsub(/^(\w)(.*)/) do 
                            $1.upcase+$2
                        end
                    end
                    n = names.last.split("_").first
                    if n == n.upcase
                        return names.join("::")
                    end

                    name = names.join("::").split("_").map do |n|
                        n.gsub(/^(\w)(.*)/) do 
                            $1.upcase+$2
                        end
                    end.join("")
                end
            end
            self.ffi_type_map ||= {"char *" => "string","unsigned char" => "uchar" ,"const char *" => "string","uint8_t" => "uint8" }

            attr_accessor :name,:full_name,:ffi
            def initialize(klass)
                super
            end

            # TODO should we automatically fix full_name ?
            def name
                if @name
                    @name
                else
                    RDataType::normalize_name(to_orig.to_raw.name)
                end
            end

            # renders the hole type as ffi string
            def render_ffi
                str = "\n#methods for #{to_orig.full_name}\n"
                if cdelete_method
                    str += "attach_function :#{cdelete_method.to_ruby.name},"\
                    ":#{t.cdelete_method},[#{full_name}],:void\n"
                    str += "attach_function :#{cdelete_method.to_ruby.name}_struct,"\
                    ":#{t.cdelete_method},[#{full_name}Struct],:void\n"
                end
                each_operation do |op|
                    str += op.to_ruby.to_ffi
                end
                str
            end

            # returns ffi signature
            def to_ffi
                if @ffi
                    @ffi
                else
                    if basic_type? || ptr? || ref?
                        ":#{RDataType::normalize_name_ffi(to_orig.to_raw.csignature)}"
                    elsif extern_package_name
                        "::#{extern_package_name}::#{RDataType::normalize_name(to_orig.to_raw.full_name)}"
                    else
                        RDataType::normalize_name(to_orig.to_raw.full_name)
                    end
                end
            end

            def full_name
                if @full_name
                    @full_name
                else
                    RDataType::normalize_name(to_orig.to_raw.full_name)
                end
            end
        end
    end
end

