require 'delegate'

module Rbind
    class RTypeQualifier < SimpleDelegator
        attr_accessor :const

        def initialize(type,options=Hash.new)
            super(type)
            const = options[:const]
        end

        def const?
            !!@const
        end

        def to_raw
            __getobj__
        end

        def raw?
            false
        end

        def generate_signatures
            str = if const?
                      "const"
                  end
            super.map do |s|
                str + s
            end
        end
    end
end
