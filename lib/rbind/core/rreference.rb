require 'delegate'

module Rbind
    class RReference < SimpleDelegator
        attr_accessor :const

        def initialize(type)
            super(type)
        end

        def to_raw
            __getobj__
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
            RTypeQualifier.new(self,:const => true)
        end

        def signature(sig=nil)
            super.to_s + "&"
        end

        def csignature(sig=nil)
            super.to_s + "&"
        end

        def generate_signatures
            super.map do |s|
                s + "&"
            end
        end
    end
end
