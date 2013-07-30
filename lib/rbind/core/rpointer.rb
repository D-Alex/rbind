require 'delegate'

module Rbind
    class RPointer < SimpleDelegator
        attr_accessor :const

        def initialize(type)
            super(type)
        end

        def name
            super.to_s + "*"
        end

        def full_name
            super.to_s + "*"
        end

        def signature(sig=nil)
            super.to_s + "*"
        end

        def csignature(sig=nil)
            super.to_s + "*"
        end

        def ptr?
            true
        end

        def ref?
            false
        end

        def raw?
            false
        end

        def remove_const
            RPointer.new __getobj__.remove_const
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

        def signature(sig=nil)
            generate_signatures[0]
        end

        def csignature(sig=nil)
            generate_signatures[1]
        end

        def generate_signatures
            __getobj__.generate_signatures.map do |s|
                s + "*"
            end
        end
    end
end
