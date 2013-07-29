require 'delegate'

module Rbind
    class RTypeQualifier < SimpleDelegator
        attr_accessor :const

        def initialize(type,options=Hash.new)
            super(type)
            @const = options[:const]
        end

        def const?
            !!@const
        end

        def to_raw
            __getobj__
        end

        def to_ptr
            RPointer.new(self)
        end

        def to_ref
            RReference.new(self)
        end

        def to_const
            RTypeQualifier.new(self,:const => true)
        end

        def raw?
            false
        end

        def signature(sig=nil)
            generate_signatures[0]
        end

        def csignature(sig=nil)
            generate_signatures[1]
        end

        def generate_signatures
            str = if const?
                      "const "
                  end
            to_raw.generate_signatures.map do |s|
                str + s
            end
        end
    end
end
