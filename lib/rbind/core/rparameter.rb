
module Rbind
    class RParameter < RAttribute
        attr_accessor :default_value

        def initialize(name,type,default_value=nil,*flags)
            super(name,type,*flags)
            self.default_value = default_value
        end

        def default_value=(val)
            val = val.to_s
            @default_value = if !val.empty?
                                 val.chomp.chomp(" ")
                             else
                                 nil
                             end
        end

        def default_value(val = nil)
            if val
                self.default_value = val
                self
            else
                @default_value
            end
        end

        def valid_flags
            [:IO,:O]
        end

        def generate_signatures
            if default_value
                super.map do |s|
                    "#{s} = #{default_value}"
                end
            else
                super
            end
        end
    end
end
