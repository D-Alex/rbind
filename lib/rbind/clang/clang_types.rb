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
            raise ArgumentError,"File #{file} does not exist!" unless File.exist?(file)
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

    # extend Structs to support auto dispose
    module Rbind
        class Cursor < FFI::Struct
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

            def referenced
                Rbind::get_cursor_referenced self
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

            def result_type
                Rbind::get_cursor_result_type self
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

            def specialized_template
                Rbind::get_specialized_cursor_template self
            end

            def template_kind
                Rbind::get_template_cursor_kind self
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
                  #  puts "#{cur.kind} #{cur.spelling} #{cur.template_kind} #{cur.specialized_template.kind} #{cur.location}"
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

        class String < FFI::Struct
            @@pointer = Hash.new

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

        class Token < FFI::Struct
            def self.release(pointer)
            end

            def spelling(translation_unit)
                Rbind::get_token_spelling(translation_unit,self).to_s
            end
        end

        class Type < FFI::Struct
            def null?
                kind == :invalid
            end

            def declaration
                Rbind::get_type_declaration self
            end

            def const_qualified?
                1 == Rbind::is_const_qualified_type(self)
            end

            def canonical_type
                Rbind::get_canonical_type self
            end

            def result_type
                Rbind::get_result_type self
            end

            def pointee_type
                Rbind::get_pointee_type self
            end

            def pod?
                1 == Rbind::is_pod_type(self)
            end

            def array_size
                Rbind::get_array_size self
            end

            def array_element_type
                Rbind::get_array_element_type self
            end

            def kind
                self[:kind]
            end
        end
    end
end
