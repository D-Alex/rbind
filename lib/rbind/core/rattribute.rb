module Rbind
    class RAttribute < RBase
        attr_accessor :type

        def initialize(name,type,*flags)
            super(name,*flags)
            raise ArgumentError,"no type" unless type
            raise "wrong name #{name}" if name =~/.*\*.*/
            @type = type
        end

        def ==(other)
            type == other.type
        end

        def generate_signatures
            @type.generate_signatures.map do |s|
                "#{s} #{name}"
            end
        end

        def valid_flags
            super << :RW
        end

        def to_ptr
            a = self.dup
            a.type = type.to_ptr
            a
        end

        def read_only?
            !write?
        end
        
        def write?
            flags.include?(:RW) || flags.include?(:IO) || flags.include?(:O)
        end
    end
end
