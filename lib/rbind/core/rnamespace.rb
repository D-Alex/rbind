
module Rbind
    class RNamespace< RDataType
        class << self
            attr_accessor :default_type_names
        end
        self.default_type_names = [:uint64,:int,:int64,:bool,:double,:float,:void,:char,:size_t]

        attr_reader :operations
        attr_reader :operation_alias
        attr_reader :consts
        attr_reader :used_namespaces
        attr_accessor :root

        def initialize(name,*flags)
            @consts = Hash.new
            @types = Hash.new
            @operations = Hash.new{|hash,key| hash[key] = Array.new}
            @operation_alias = Hash.new{|hash,key| hash[key] = Array.new}
            @used_namespaces = Hash.new
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

        def each_type(childs=true,&block)
            if block_given?
                types.each do |t|
                    yield t
                    t.each_type(&block) if childs && t.respond_to?(:each_type)
                end
            else
                Enumerator.new(self,:each_type,childs)
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

        def add_operation(op)
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
                           name = "#{op.name}#{@operations[op.name].size+1}"
                           ::Rbind.log.debug "name clash: #{op.name} --> #{name}"
                           name
                       end
            @operations[op.name] << op
            @operation_alias[op.alias] << op if op.alias
            op
        end

        def add_namespace(namespace)
            names = namespace.split("::")
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
            add_type ::Rbind::RDataType.new("uchar").cname("unsigned char")
            add_type ::Rbind::RDataType.new("c_string").cname("char *")
            add_type ::Rbind::RDataType.new("const_c_string").cname("const char *")
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

        def add_type(type)
            raise ArgumentError, "wrong parmeter type #{type}" unless type.is_a? RDataType
            if type(type.full_name,false,false)
                raise ArgumentError,"A type with the name #{type.full_name} already exists"
            end
            # if self is not the right namespace
            if type.namespace? && self.full_name != type.namespace && !(self.full_name =~/(.*)::#{type.namespace}/)
                t=type(type.namespace,false)
                t ||=add_namespace(type.namespace)
                t.add_type(type)
            else
                type.owner = self
                @types[type.name] = type
            end
            type
        end

        def type(name,raise_ = true,search_owner = true)
            ptr = name.include?("*")
            ref = name.include?("&")
            if(ptr && ref)
                raise ArgumentError,"given type is a reference and pointer at the same time: #{name}"
            end
            name = name.gsub("*","").gsub("&","")
            name = name.chomp(" ")
            t = if @types.has_key?(name)
                    @types[name]
                else
                    if !!(ns = RBase.namespace(name))
                        ns = ns.split("::")
                        ns << RBase.basename(name)
                        t = type(ns.shift,false)
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
            raise RuntimeError,"#{full_name} has no type called #{name}" if raise_ && !t
            if t && (ptr || ref)
                t = t.clone
                t.ref = ref
                t.ptr = ptr
            end
            t
        end

        def pretty_print_name
            "namespace #{full_name}#{" Flags: #{flags.join(", ")}" unless flags.empty?}"
        end

        def root?
            !!root
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
            t = type(m.to_s,false)
            return t if t

            op = operation(m.to_s,false)
            return op if op

            super
        end
    end
end



