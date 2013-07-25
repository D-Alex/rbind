module Clang

    class Clang
        @@index = Hash.new
        attr_reader :units

        def initialize
            ObjectSpace.define_finalizer(self, Clang.method(:finalize))
            @index = Rbind::create_index(1, 1)
            @@index[self.object_id] = @index
            @units = []
        end

        def translation_unit(file,args)
            @pargs = args.map do |a|
                FFI::MemoryPointer.from_string(a)
            end
            @cargs = FFI::MemoryPointer.new(:pointer, @pargs.size)
            @cargs.write_array_of_pointer(@pargs)
            tu = Rbind::parse_translation_unit(@index,file,@cargs,@pargs.size,nil,0,1)
            # auto release if Clang goes out of scope
            # this cannot be encapsulate into the obj because
            # each cursor can return a pointer to the unit
            @units << TranslationUnitImplStruct.new(FFI::AutoPointer.new(tu.__obj_ptr__.pointer,TranslationUnitImplStruct.method(:release)))
            tu
        end

        # dispose index
        def self.finalize(id)
            Rbind::dispose_index(@@index[id])
            @@index.delete(id)
        end
    end

    # A single translation unit, which resides in an index.
    class TranslationUnitImplStruct < FFI::Struct
        layout :dummy, :char

        # do not call this for each instance !
        # class Clang is taking care of this
        def self.release(pointer)
            Rbind::dispose_translation_unit(pointer) unless pointer.null?
        rescue Exception => e
            puts e
        end
    end

    class TranslationUnitImpl
        extend FFI::DataConverter
        native_type FFI::Type::POINTER

        def self.to_native(obj,context)
            if obj.is_a? TranslationUnitImpl
                obj.__obj_ptr__
            else
                raise TypeError, "expected kind of #{name}, was #{obj.class}"
            end
        end

        def self.from_native(ptr,context)
            TranslationUnitImpl.new(ptr)
        end

        attr_reader :__obj_ptr__
        def initialize(ptr)
            @__obj_ptr__ = if ptr.is_a? TranslationUnitImplStruct
                               ptr
                           else
                               TranslationUnitImplStruct.new(ptr)
                           end
        end

        def cursor
            cu = Rbind::get_translation_unit_cursor(self)
            cu.instance_variable_set(:@__translation_unit__,self)
            cu
        end
  
        def spelling
            Rbind::get_translation_unit_spelling(self).to_s
        end
    end

    # A cursor representing some element in the abstract syntax tree for
    # a translation unit.
    # 
    # The cursor abstraction unifies the different kinds of entities in a
    # program--declaration, statements, expressions, references to declarations,
    # etc.--under a single "cursor" abstraction with a common set of operations.
    # Common operation for a cursor include: getting the physical location in
    # a source file where the cursor points, getting the name associated with a
    # cursor, and retrieving cursors for any child nodes of a particular cursor.
    # 
    # Cursors can be produced in two specific ways.
    # clang_getTranslationUnitCursor() produces a cursor for a translation unit,
    # from which one can use clang_visitChildren() to explore the rest of the
    # translation unit. clang_getCursor() maps from a physical source location
    # to the entity that resides at that location, allowing one to map from the
    # source code into the AST.
    # 
    # = Fields:
    # :kind ::
    #   (Symbol from _enum_cursor_kind_) 
    # :xdata ::
    #   (Integer) 
    # :data ::
    #   (Array<FFI::Pointer(*Void)>) 
    class Cursor < FFI::Struct
        layout :kind, :int,
            :xdata, :int,
            :data, [:pointer, 3]

        def null?
           1 == Rbind::cursor_is_null(self)
        end

        def location
            line = FFI::MemoryPointer.new(:uint,1)
            col = FFI::MemoryPointer.new(:uint,1)
            location = Rbind::get_cursor_location(self)
            fstr = String.new
            Rbind::get_presumed_location(location,fstr,line,col)
            result = [fstr.to_s,line.get_uint(0),col.get_uint(0)]
            result
        end

        def file_name
            location[0]
        end

        def line
            location[1]
        end

        def column
            location[2]
        end

        def cxx_access_specifier
            Rbind::get_cxx_access_specifier self
        end

        def extent
            Rbind::get_cursor_extent self
        end

        def expression
            num = FFI::MemoryPointer.new(:uint,1)
            tokens = FFI::MemoryPointer.new(:pointer,1)
            tu = translation_unit
            Rbind::tokenize(tu,extent,tokens,num)
            ptr = FFI::Pointer.new(Token,tokens.read_pointer)
            result = 0.upto(num.read_uint-1).map do |i|
                Rbind::get_token_spelling(tu,ptr[i])
            end
            Rbind::dispose_tokens(tu,ptr,num.get_uint(0))
            result
        end

        def kind_spelling
            Rbind::get_cursor_kind_spelling(self).to_s
        end

        def spelling
            Rbind::get_cursor_spelling(self).to_s
        end

        def display_name
            Rbind::get_cursor_display_name(self).to_s
        end

        def kind
            Rbind::get_cursor_kind(self)
        end

        def translation_unit
            Rbind::cursor_get_translation_unit(self)
        end

        def result_type
            Rbind::get_cursor_result_type self
        end

        def type
            Rbind::get_cursor_type self
        end

        def virtul_base?
            1 == Rbind::is_virtual_base(self)
        end

  #attach_function :get_cxx_access_specifier, :clang_getCXXAccessSpecifier, [Cursor.by_value], :cxx_access_specifier
  #attach_function :is_cursor_definition, :clang_isCursorDefinition, [Cursor.by_value], :uint
  #attach_function :get_canonical_cursor, :clang_getCanonicalCursor, [Cursor.by_value], Cursor.by_value
  #attach_function :cxx_method_is_static, :clang_CXXMethod_isStatic, [Cursor.by_value], :uint
    #attach_function :cxx_method_is_virtual, :clang_CXXMethod_isVirtual, [Cursor.by_value], :uint
  #attach_function :get_num_overloaded_decls, :clang_getNumOverloadedDecls, [Cursor.by_value], :uint

        def visit_children(recurse=false,&block)
            orig_file = translation_unit.spelling
            p = proc do |cur,parent,data|
                if cur.file_name != orig_file
                    :continue
                else
                    block.call(cur,parent)
                    if recurse
                        :recurse
                    else
                        :continue
                    end
                end
            end
            Rbind::visit_children(self,p,FFI::Pointer.new(0))
        end
    end

    # A character string.
    # 
    # The \c CXString type is used to return strings from the interface when
    # the ownership of that string might different from one call to the next.
    # Use \c clang_getCString() to retrieve the string data and, once finished
    # with the string data, call \c clang_disposeString() to free the string.
    # 
    # = Fields:
    # :data ::
    #   (FFI::Pointer(*Void)) 
    # :private_flags ::
    #   (Integer) 
    class String < FFI::Struct
        @@pointer = Hash.new

        layout :data, :pointer,
            :private_flags, :uint

        def self.finalize(id)
            Rbind::dispose_string(@@pointer[id])
            @@pointer.delete(id)
        rescue Exception => e
            puts e
        end

        def initialize(*args)
            super
            # we cannot use auto pointer because string is returned as value
            ObjectSpace.define_finalizer(self, String.method(:finalize))
            @@pointer[self.object_id] = pointer
        end

        def to_s
            Rbind.get_c_string self
        end
    end

    # Describes a single preprocessing token.
    # 
    # = Fields:
    # :int_data ::
    #   (Array<Integer>) 
    # :ptr_data ::
    #   (FFI::Pointer(*Void)) 
    class Token < FFI::Struct
        layout :int_data, [:uint, 4],
            :ptr_data, :pointer

        def self.release(pointer)
        end

        def spelling(translation_unit)
            Rbind::get_token_spelling(translation_unit,self).to_s
        end
    end

  # The type of an element in the abstract syntax tree.
  # 
  # = Fields:
  # :kind ::
  #   (Symbol from _enum_type_kind_) 
  # :data ::
  #   (Array<FFI::Pointer(*Void)>) 
  class Type < FFI::Struct
    layout :kind, :int,
           :data, [:pointer, 2]

    def kind
        Rbind::get_type_kind(self).to_s
    end
  end
  
end
