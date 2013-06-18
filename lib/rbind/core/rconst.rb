
module Rbind
    class RConst < RDataType
        attr_accessor :value

        def initialize(name,value,*flags)
            super(name,*flags)
            @value = value
        end

        def generate_signatures
            ["#{full_name} = #{value}","const int #{cname} = #{map_value_to_namespace(value)}"]
        end

        def map_value_to_namespace(value)
            a = value.split(" ")
            a = a.map do |str|
                if str =~/^[a-zA-Z]/
                    RBase.to_cname("#{namespace}::#{str}")
                else
                    str
                end
            end
            a.join(" ")
        end

        def basic_type?
            false
        end

        def pretty_print(pp)
            pp.text "#{signature}#{" Flags: #{flags.join(", ")}" unless flags.empty?}"
        end
    end
end
