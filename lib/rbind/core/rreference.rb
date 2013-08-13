require 'delegate'

module Rbind
    class RReference < SimpleDelegator
        attr_accessor :const

        def initialize(type)
            super(type)
        end

        def ref?
            true
        end

        def ptr?
            false
        end

        def raw?
            false
        end

        def to_ptr
            RPointer.new(self)
        end

        def to_ref
            RReference.new(self)
        end

        def to_const
            return self if const?
            RTypeQualifier.new(self,:const => true)
        end

        def remove_const
            RReference.new __getobj__.remove_const
        end

        def signature(sig=nil)
            generate_signatures[0]
        end

        def csignature(sig=nil)
            generate_signatures[1]
        end

        def generate_signatures
            __getobj__.generate_signatures.map do |s|
                s + "&"
            end
        end
    end
end
