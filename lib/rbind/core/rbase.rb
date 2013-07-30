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
                if cn =~ /operator/
                    cn = cn.gsub("operator()","operator_fct")
                    cn = cn.gsub("operator!=","operator_unequal")
                    cn = cn.gsub("operator==","operator_equal")
                    cn = cn.gsub("operator&=","operator_and_set")
                    cn = cn.gsub("operator+=","operator_add")
                    cn = cn.gsub("operator-=","operator_sub")
                    cn = cn.gsub("operator+","operator_plus")
                    cn = cn.gsub("operator-","operator_minus")
                    cn = cn.gsub("operator*","operator_mult")
                    cn = cn.gsub("operator/","operator_div")
                    cn = cn.gsub("operator!","operator_not")
                    cn = cn.gsub("operator&","operator_and")
                    cn = cn.gsub("operator[]","operator_array")
                end
                cn = cn.gsub("*","_ptr")
                cn = cn.gsub("&","_ref")
                cn = cn.gsub("<","_")
                cn = cn.gsub(">","")
                cn = cn.gsub(",","__")
            end

            def normalize(name)
                name = name.to_s
                if name.split("/n").size > 1
                    raise "mulitple lines for a name is not supported: #{name}"
                end
                name.gsub(".","::").gsub(" ","")
            end

            def split_name(name)
                name = normalize(name)
                # check for template
                if(name =~/([\w:]*)(<.*)$/)
                    result = split_name($1)
                    [result[0],result[1]+$2]
                elsif(name =~/(.*)::(.*)$/)
                    [$1,$2]
                else
                    [nil,name]
                end
            end

            def namespace(name)
                split_name(name)[0]
            end

            def basename(name)
                split_name(name)[1]
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
            self.flags = flags.flatten.uniq.compact
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
            valid_flags = valid_flags.flatten
            flags.each do |flag|
                next unless flag
                if !valid_flags.include?(flag)
                    raise "flag #{flag} is not supported for #{self.class.name}. Supported flags are #{valid_flags}"
                end
            end
        end

        def owner=(obj)
            raise ArgumentError,"Cannot at self as owner" if obj == self
            @owner = obj
            @namespace = nil
        end

        def ignore?
            !!@ignore
        end

        def namespace
            if @namespace
                @namespace
            elsif @owner.respond_to?(:root?) && !@owner.root?
                @owner.full_name
            else
                nil
            end
        end

        def namespace?
            namespace && namespace.size != 0
        end

        def full_name
            map_to_namespace(name)
        end

        def to_s
            signature
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
