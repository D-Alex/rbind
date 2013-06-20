# object wrapping <%= full_name %>
class <%= name %>Struct < FFI::Struct
    layout :version,:uchar,
           :size,:size_t,
           :type_id,:pointer,
           :obj_ptr,:pointer,
           :bowner,:bool
    # auto delete
    def self.release(pointer)
        Rbind::<%= cdelete_method %>_struct(pointer) unless pointer.null?
    rescue Exception => e
        puts e
    end
end

class <%= name %>
    extend FFI::DataConverter
    native_type FFI::Type::POINTER

    def self.new(*args)
        if args.first.is_a?(FFI::Pointer) || args.first.is_a?(<%= name %>Struct)
            raise ArgumentError, "too many arguments for creating #{self.name} from Pointer" unless args.size == 1
            return super(args.first)
        end
<%= add_constructor %>
        raise ArgumentError, "no constructor for #{self}(#{args.inspect})"
    end

    def self.rbind_to_native(obj,context)
        if obj.is_a? <%= name %>
            obj.__obj_ptr__
        else
            raise TypeError, "expected kind of #{name}, was #{obj.class}"
        end
    end

    def self.rbind_from_native(ptr,context)
        <%= name %>.new(ptr)
    end

    # can be overwritten by the user
    def self.to_native(obj,context)
        rbind_to_native(obj,context)
    end

    # can be overwritten by the user
    def self.from_native(ptr,context)
        rbind_from_native(ptr,context)
    end

    attr_reader :__obj_ptr__
    def initialize(ptr)
        @__obj_ptr__ = if ptr.is_a? <%= name %>Struct
                           ptr
                       else
                           <%= name %>Struct.new(FFI::AutoPointer.new(ptr,<%= name %>Struct.method(:release)))
                       end
    end

    # returns true if the underlying pointer is owner of
    # the real object
    def __owner__?
        @__obj_ptr__[:bowner]
    end

    # custom specializing
<%= add_specializing %>

    # consts
<%= add_consts %>

    # methods
<%= add_methods %>
    # types
<%= add_types %>
end

