
module Rbind
    class RDataType < RBase
        attr_accessor :ptr,:ref
        attr_accessor :typedef
        attr_accessor :invalid_value
        attr_accessor :cdelete_method
        attr_accessor :check_type
        attr_accessor :extern_package_name

        def initialize(name,*flags)
            super
            @invalid_value = 0
            @check_type = true
        end

        def extern?
           @flags.include? :Extern
        end

        def valid_flags
            super << :Extern
        end

        def ==(other)
            other.generate_signatures[0] == generate_signatures[0]
        end

        def generate_signatures
            super
        end

        # indicates of the type shall be checked before 
        # casting
        def check_type?
            @check_type
        end

        def cname(value=nil)
            if !value
                if basic_type? && !@cname
                    name
                else
                    super
                end
            else
                super
                self
            end
        end

        def typedef(value=nil)
            return @typedef unless value
            @typedef = value
            self
        end

        def typedef?
            !!@typedef
        end

        # elementar type of c
        def basic_type?
            true
        end

        # holds ofther operations, types or consts
        def container?
            false
        end

        def to_raw
            self
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
            true
        end

        def const?
            false
        end

        def ptr?
            false
        end

        def ref?
            false
        end

        def delete!
            if @owner
                @owner.delete_type self.name
            else
                raise "#{self} has no owner."
            end
        end
    end
end
