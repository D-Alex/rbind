require 'hooks'

module Rbind
    class RNamespace< RDataType
        include Hooks
        define_hook :on_type_not_found
        define_hook :on_type_look_up
        define_hook :on_add_type
        define_hook :on_add_operation
        define_hook :on_add_const

        class << self
            attr_accessor :default_type_names
            attr_accessor :default_type_alias
        end
        # TODO move somewhere else
        self.default_type_names = [:int,:int8,:int32,:int64,:uint,:uint8,:uint32,:uint64,
                                   :int8_t,:int32_t,:int64_t,:uint8_t,:uint32_t,:uint64_t,
                                   :bool,:double,:float,:void,:char,:size_t,:long,
                                   :uchar, :char16, :char32, :ushort, :ulong, :ulong_long,
                                   :uint128, :short, :long_long, :int128, :long_double,
                                   :c_string]
        self.default_type_alias= { :u_char => :uchar, :u_short => :ushort, :u_long => :ulong,
                                   :u_long_long => :ulong_long,:u_int => :uint, :uint128 => :uint128,
                                   :char_s => :char}

        attr_reader :operations
        attr_reader :operation_alias
        attr_reader :consts
        attr_reader :enums
        attr_reader :used_namespaces
        attr_accessor :root
        attr_accessor :type_alias

        def initialize(name=nil,*flags)
            @consts = Hash.new
            @enums = Hash.new
            @types = Hash.new
            @type_alias = Hash.new
            @operations = Hash.new{|hash,key| hash[key] = Array.new}
            @operation_alias = Hash.new{|hash,key| hash[key] = Array.new}
            @used_namespaces = Hash.new
            name ||= begin
                         @root = true
                         "root"
                     end
            super(name,*flags)
        end

        def root?
            !!root
        end

        def constructor?
            false
        end

        def types
            @types.values
        end

        def delete_type(name)
            ns = RBase.namespace(name)
            if ns
                type(ns).delete_type(RBase.basename(name))
            else
                @types.delete(name)
            end
        end

        def use_namespace(namespace)
            @used_namespaces[namespace.name] = namespace
        end

        def each_type(childs=true,all=false,&block)
            if block_given?
                types.each do |t|
                    next if !all && (t.ignore? || t.extern?)
                    yield t
                    t.each_type(childs,all,&block) if childs && t.respond_to?(:each_type)
                end
            else
                Enumerator.new(self,:each_type,childs,all)
            end
        end

        def each_container(all=false,&block)
            each_type(true,all) do |t|
                next unless t.container?
                yield t
            end
        end

        def consts
            @consts.values
        end

        def const(name,raise_ = true,search_owner = true)
            c = if @consts.has_key?(name)
                    @consts[name]
                else
                    if !!(ns = RBase.namespace(name))
                        t = type(ns,false)
                        t.const(RBase.basename(name),false,false) if t
                    end
                end
            c ||= begin
                      used_namespaces.values.each do |ns|
                          c = ns.const(name,false,false)
                          break if c
                      end
                      c
                  end
            c ||= if search_owner && owner
                      owner.const(name,false)
                  end
            raise RuntimeError,"#{full_name} has no const called #{name}" if raise_ && !c
            c
        end

        def each_const(childs=true,all=false,&block)
            if block_given?
                consts.each do |c|
                    next if !all && (c.ignore? || c.extern?)
                    yield c
                end
                return unless childs
                each_container(all) do |t|
                    t.each_const(childs,all,&block)
                end
            else
                Enumerator.new(self,:each_const,childs,all)
            end
        end

        def extern?
            return super() if self.is_a?(RStruct)

            # check if self is container holding only
            # extern objects
            each_type(false) do |t|
                return false if !t.extern?
            end
            each_const(false) do |c|
                return false if !c.extern?
            end
            each_operation do |t|
                return false
            end
            true
        end

        def each_operation(all=false,&block)
            if block_given?
                operations.each do |ops|
                    ops.each do |o|
                        next if !all && o.ignore?
                        yield o
                    end
                end
            else
                Enumerator.new(self,:each_operaion,all)
            end
        end

        def operations
            @operations.values
        end

        def container?
            true
        end

        def operation(name,raise_=true)
            ops = @operations[name]
            if(ops.size == 1)
                ops.first
            elsif ops.empty?
                @operations.delete name
                raise "#{full_name} has no operation called #{name}." if raise_
            else
                ops
            end
        end

        def operation?(name)
            !!operation(name,false)
        end

        def add_operation(op,&block)
            if op.is_a? String
                op = ROperation.new(op,void)
                op.owner = self
                instance_exec(op,&block) if block
                return add_operation(op)
            end

            op.owner = self
            # make sure there is no name clash
            other = @operations[op.name].find do |o|
                o.cname == op.cname
            end
            other ||= @operation_alias[op.name].find do |o|
                o.cname == op.cname
            end
            op.alias = if !other
                           op.alias
                       elsif op.alias
                           name = "#{op.alias}#{@operations[op.name].size+1}"
                           ::Rbind.log.debug "name clash: aliasing #{op.alias} --> #{name}"
                           name
                       else
                           op.auto_alias = true
                           name = "#{op.name}#{@operations[op.name].size+1}"
                           ::Rbind.log.debug "name clash: #{op.name} --> #{name}"
                           name
                       end
            op.index = @operations[op.name].size
            @operations[op.name] << op
            @operation_alias[op.alias] << op if op.alias
            op
        end

        # TODO rename to add_namespace_name
        def add_namespace(namespace_name)
            names = namespace_name.split("::")
            current_type = self
            while !names.empty?
                name = names.shift
                temp = current_type.type(name,false,false)
                current_type = if temp
                                   temp
                               else
                                   ::Rbind.log.debug "missing namespace: add #{current_type.full_name unless current_type.root?}::#{name}"
                                   current_type.add_type(RNamespace.new(name))
                               end
            end
            current_type
        end

        def add_const(const)
            if const(const.full_name,false,false)
                raise ArgumentError,"#A const with the name #{const.full_name} already exists"
            end
            if const.namespace? && self.full_name != const.namespace
                t=type(const.namespace,false)
                t ||= add_namespace(const.namespace)
                t.add_const(const)
            else
                const.owner = self
                @consts[const.name] = const
            end
            const
        end

        def add_default_types
            add_simple_types RNamespace.default_type_names
            type("uchar").cname("unsigned char")
            type("c_string").cname("char *")
            RNamespace.default_type_alias.each_pair do |key,val|
                next if @type_alias.has_key?(key)
                @type_alias[key.to_s] = type(val)
            end
            self
        end

        def add_simple_type(name)
            add_type(RDataType.new(name))
        end

        def add_simple_types(*names)
            names.flatten!
            names.each do |n|
                add_simple_type(n)
            end
        end

        def add_type(type,check_exist = true)
            if check_exist && type(type.full_name,false,false)
                raise ArgumentError,"A type with the name #{type.full_name} already exists"
            end
            # if self is not the right namespace
            if type.namespace? && self.full_name != type.namespace && !(self.full_name =~/(.*)::#{type.namespace}/)
                t=type(type.namespace,false)
                t ||=add_namespace(type.namespace)
                t.add_type(type)
            else
                type.owner = self
                if type.alias
                    if check_exist && type(type.alias,false,false)
                        raise ArgumentError,"A type with the name alias #{type.alias} already exists"
                    end
                    @type_alias[type.alias] = type
                end
                @types[type.name] = type
            end
            type
        end

        def type(name,raise_ = true,search_owner = true)
            name = name.to_s
            const = name.count("const ")
            name = name.gsub("unsigned ","u").gsub("const ","").gsub(" ","")

            t = if @types.has_key?(name)
                    @types[name]
                elsif @type_alias.has_key?(name)
                    @type_alias[name]
                else
                    if !!(ns = RBase.namespace(name))
                        ns = ns.split("::")
                        ns << RBase.basename(name)
                        t = type(ns.shift,false,false)
                        t.type(ns.join("::"),false,false) if t
                    end
                end
            t ||= begin
                      used_namespaces.values.each do |ns|
                          t = ns.type(name,false,false)
                          break if t
                      end
                      t
                  end
            t ||= if search_owner && owner
                      owner.type(name,false)
                  end
            # check if type is a pointer and pointee is registered
            t ||= begin
                      ptr_level = $1.to_s.size if name  =~ /(\**)$/
                      name2 = name.gsub("*","")
                      ref_level = $1.to_s.size if name2  =~ /(&*)$/
                      name2 = name2.gsub("&","")
                      if ptr_level > 0 || ref_level > 0
                          t = type(name2,raise_,search_owner)
                          if t
                              1.upto(ptr_level) do
                                  t = t.to_ptr
                              end
                              1.upto(ref_level) do
                                  t = t.to_ref
                              end
                              t.owner.add_type(t,false)
                              t
                          end
                      end
                  end

            # check if type is a template and a template is registered
            # under the given name
            t ||=  if name =~ /([:\w]*)<(.*)>$/
                      t = type($1,false)
                      t2 = type($2,false)
                      if t && t2
                          t3 = t.specialize(name,t2)
                          ::Rbind.log.info "spezialize template #{t.full_name} --> #{t3.full_name}"
                          t.owner.add_type(t3,false)
                          t3
                      end
                    end

            if !t && raise_
                if self.class.callbacks_for_hook(:on_type_not_found)
                    results = self.run_hook(:on_type_not_found,self,name)
                    t = results.find do |t|
                        t.respond_to?(:type)
                    end
                end
                raise RuntimeError,"#{full_name} has no type called #{name}" if !t
            end
            t
        end

        def pretty_print_name
            "namespace #{full_name}#{" Flags: #{flags.join(", ")}" unless flags.empty?}"
        end

        def root?
            !!root
        end

        def empty?
            consts.empty? && types.empty? && operations.empty?
        end

        def pretty_print(pp)
            pp.text pretty_print_name

            unless consts.empty?
                pp.nest(2) do
                    pp.breakable
                    pp.text "Consts:"
                    pp.nest(2) do
                        consts.each do |c|
                            pp.breakable
                            pp.pp(c)
                        end
                    end
                end
            end
            unless types.empty?
                pp.nest(2) do
                    pp.breakable
                    pp.text "Types:"
                    pp.nest(2) do
                        types.each do |t|
                            pp.breakable
                            pp.pp(t)
                        end
                    end
                end
            end

            unless operations.empty?
                pp.nest(2) do
                    pp.breakable
                    pp.text "Operations:"
                    pp.nest(2) do
                        operations.each do |op|
                            op.each do |o|
                                pp.breakable
                                pp.pp(o)
                            end
                        end
                    end
                end
            end
        end

        def method_missing(m,*args)
            if m != :to_ary && args.empty?
                t = type(m.to_s,false,false) if m != :to_ary
                return t if t

                op = operation(m.to_s,false)
                return op if op

                e = enum(m.to_s,false)
                return e if e

                c = const(m.to_s,false)
                return c if c
            end
            super
        end
    end
end



