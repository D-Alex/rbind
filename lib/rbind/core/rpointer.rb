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

        def to_raw
            __getobj__
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

        def to_ptr
            RPointer.new(self)
        end

        def to_ref
            RReference.new(self)
        end

        def to_const
            RTypeQualifier.new(self,:const => true)
        end


        def generate_signatures
            super.map do |s|
                s + "*"
            end
        end
    end
end
