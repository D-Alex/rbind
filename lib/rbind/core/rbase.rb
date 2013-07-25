module Rbind
    class RBase
        attr_accessor :name
        attr_accessor :cname
        attr_accessor :alias
        attr_accessor :auto_alias # set to true if rbind is aliasing the object
        attr_accessor :namespace
        attr_accessor :owner
        attr_accessor :flags
        attr_accessor :version
        attr_accessor :signature
        attr_accessor :csignature
        attr_accessor :ignore

        class << self
            attr_accessor :cprefix

            def to_cname(name)
                name = normalize(name)
                cn = "#{cprefix}#{name.gsub("::","_")}"
                cn = cn.gsub("()","_fct")
                cn = cn.gsub("!=","_unequal")
                cn = cn.gsub("==","_equal")
                cn = cn.gsub("&=","_and_set")
                cn = cn.gsub("+=","_add")
                cn = cn.gsub("-=","_sub")
                cn = cn.gsub("+","_plus")
                cn = cn.gsub("-","_minus")
                cn = cn.gsub("*","_mult")
                cn = cn.gsub("/","_div")
                cn = cn.gsub("!","_not")
                cn = cn.gsub("&","_and")
                cn.gsub("[]","_array")
            end

            def normalize(name)
                name = name.to_s
                if name.split("/n").size > 1
                    raise "mulitple lines for a name is not supported: #{name}"
                end
                name.gsub(".","::").gsub(" ","")
            end

            def basename(name)
                name = normalize(name)
                if !!(name =~/.*::(.*)$/)
                    $1
                else
                    name
                end
            end

            def namespace(name)
                name = normalize(name)
                if !!(name =~/(.*)::.*$/)
                    $1
                else
                    nil
                end
            end
        end
        self.cprefix = "rbind_"

        def pretty_print(pp)
            pp.text "#{signature}#{" Flags: #{flags.join(", ")}" unless flags.empty?}"
        end

        def initialize(name,*flags)
            name = RBase::normalize(name)
            raise ArgumentError, "no name" unless name && name.size > 0
            @name = RBase::basename(name)
            @namespace = RBase::namespace(name)
            @version = 1
            self.flags = flags.flatten
        end

        def generate_signatures
            ["#{full_name}","#{cname}"]
        end

        def ignore?
            !!@ignore
        end

        def signature(sig=nil)
            return @signature || generate_signatures[0] unless sig
            @signature = sig
        end

        def csignature(sig=nil)
            return @csignature || generate_signatures[1] unless sig
            @csignature = sig
        end

        def alias(val=nil)
            return @alias if !val || val.empty?
            @alias = val
            self
        end

        def alias=(val)
            self.alias(val)
            val
        end

        def cname(name=nil)
            if name
                @cname = name
                self
            else
                if @cname
                    @cname
                elsif @alias
                    RBase::to_cname(map_to_namespace(@alias))
                else
                    RBase::to_cname(full_name)
                end
            end
        end

        def flags=(*flags)
            flags.flatten!
            validate_flags(flags)
            @flags = flags
        end

        def add_flag(*flags)
            @flags += flags
            self
        end

        def valid_flags
            []
        end

        def validate_flags(flags,valid_flags = self.valid_flags)
            valid_flags.flatten!
            flags.each do |flag|
                if !valid_flags.include?(flag)
                    raise "flag #{flag} is not supported for #{self.class.name}. Supported flags are #{valid_flags}"
                end
            end
        end

        def owner=(obj)
            if obj.respond_to?(:root?) && !obj.root?
                @namespace = obj.full_name
            else
                @namespace = nil
            end
            @owner = obj
        end

        def ignore?
            !!@ignore
        end

        def namespace?
            namespace && namespace.size != 0
        end

        def full_name
            map_to_namespace(name)
        end

        def to_s
            full_name
        end

        def map_to_namespace(name)
            if namespace
                "#{namespace}::#{name}"
            else
                name
            end
        end

        def binding
            Kernel.binding
        end
    end
end
