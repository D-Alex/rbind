
module Rbind
    class RDataType < RBase
        attr_accessor :ptr,:ref
        attr_accessor :typedef
        attr_accessor :invalid_value
        attr_accessor :cdelete_method;
        attr_accessor :check_type;

        def initialize(name,*flags)
            super
            @invalid_value = 0
            @type_check = true
        end

        def ==(other)
            other.name == name && other.ptr == ptr
        end

        def generate_signatures
            if ref?
                ["#{full_name} &","#{cname} &"]
            elsif ptr?
                ["#{full_name} *","#{cname} *"]
            else
                super
            end
        end

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

        def basic_type?
            true
        end

        def container?
            false
        end

        def to_value
            owner.type(name)
        end

        def to_ptr
            return self if ptr? && !ref?
            t = self.dup
            t.ref = false
            t.ptr = true
            t
        end

        def delete!
            if @owner
                @owner.delete_type self.name
            else 
                raise "#{self} has no owner."
            end
        end

        def ptr?
            !!ptr
        end

        def ref?
            !!ref
        end
    end
end
