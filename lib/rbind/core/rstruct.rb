
module Rbind
    class RStruct < RNamespace
        attr_reader :attributes

        def initialize(name,*flags)
            @attributes = Hash.new
            super(name,*flags)
        end

        def basic_type?
            false
        end

        def valid_flags
            super << :Simple << :Map
        end

        def constructor?
            ops = Array(operation(name,false))
            return false unless ops
            op = ops.find do |op|
                op.constructor?
            end
            !!op
        end

        def attributes
            @attributes.values
        end

        def attribute(name)
            @attributes[name]
        end

        def cdelete_method
            if @cdelete_method
                @cdelete_method
            else
                if cname =~ /^#{RBase.cprefix}(.*)/
                    "#{RBase.cprefix}delete_#{$1}"
                else
                    "#{RBase.cprefix}delete_#{name}"
                end
            end
        end

        def add_attribute(attr)
            if attr.namespace?
                type(attr.namespace).add_attribute(attr)
            else
                if @attributes.has_key? attr.name
                    raise "#An attribute with the name #{attr.name} already exists"
                end
                attr.owner = self
                @attributes[attr.name] = attr
                # add getter and setter methods to the object
                add_operation(RGetter.new(attr))
                add_operation(RSetter.new(attr)) if attr.write?
            end
            self
        end

        def pretty_print_name
            "struct #{full_name}#{" Flags: #{flags.join(", ")}" unless flags.empty?}"
        end

        def pretty_print(pp)
            super
            unless attributes.empty?
                pp.nest(2) do
                    pp.breakable
                    pp.text "Attributes:"
                    pp.nest(2) do
                        attributes.each do |a|
                            pp.breakable
                            pp.pp(a)
                        end
                    end
                end
            end
        end
    end
end



