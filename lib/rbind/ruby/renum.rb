
module Rbind
    module Ruby
        class << self
            def normalize_name(name)
                name = GeneratorRuby.normalize_basic_type_name_ffi name
                #to lower and substitute namespace :: with _
                name = name.gsub("::","_")
                name = name.downcase
                name
            end
        end

        class REnum < DelegateClass(::Rbind::REnum)
            attr_accessor :name

            def initialize(klass)
                super
            end

            def render_ffi
                str = "\tenum :#{name}, ["
                values.each do |name,value|
                    if value
                        str += ":#{name},#{value}, "
                    else
                        str += ":#{name}, "
                    end
                end
                str += "]\n\n"
            end

            def name
                if @name
                    @name
                else
                    REnum::normalize_name(to_orig.name)
                end
            end
        end
    end
end
