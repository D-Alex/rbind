
module Rbind
    class REnum < RDataType
        attr_accessor :values

        def initialize(name,*flags)
            super(name,*flags)
            @values = Hash.new
        end

        def generate_signatures
            ["#{full_name} = #{values}","const #{cname} = #{values}"]
        end

        def basic_type?
            false
        end

        def add_value(name,val)
            @values[name] = val
        end

        def pretty_print(pp)
            pp.text "#{signature}#{" Flags: #{flags.join(", ")}" unless flags.empty?}"
        end
    end
end
