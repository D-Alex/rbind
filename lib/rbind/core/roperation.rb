
module Rbind
    class ROperation < RBase
        attr_accessor :return_type
        attr_accessor :parameters
        attr_accessor :cparameters
        attr_accessor :base_class
        attr_accessor :ambiguous_name
        attr_accessor :index            # index if overloaded
        attr_accessor :static

        def initialize(name,return_type,*args)
            super(name)
            @return_type = return_type
            @parameters = args.flatten
        end

        def add_parameter(para,&block)
            para = if para.is_a? String
                raise "No owner. Cannot create parameter" unless owner
                para = RParameter.new(para,owner.void)
                owner.instance_exec(para,&block) if block
                para
            else
                para
            end
            if @parameters.find{|p| p.name == para.name}
                raise RuntimeError,"duplicate parameter name #{para}"
            end
            @parameters << para
        end

        def ==(other)
            return false if other.class != self.class
            return false unless name == other.name
            @parameters.each_with_index do |p,i|
                return false if p != other.parameters[i]
            end
            true
        end

        # returns true if the operations is in inherit 
        # from one of the base classes
        def inherit?
            @base_class != @owner
        end

        def operator?
            op = operator
            op && op != '[]' && op != '()'
        end

        # for now returns true if the owner class
        # has no constructor
        def abstract?
            !base_class.operation(base_class.name,false)
        end

        # operations with ambiguous name lookup due to multi inheritance
        def ambiguous_name?
            !!@ambiguous_name
        end

        def operator
            name =~ /operator ?(.*)/
            $1
        end

        def parameter(idx)
            @parameters[idx]
        end

        def static?
            !!@static
        end

        def to_static
            op = self.dup
            op.static = true
            op
        end

        def generate_signatures
            s = "#{return_type.signature} " unless constructor?
            s = "#{s}#{full_name}(#{parameters.map(&:signature).join(", ")})"
            
            cs = if constructor?
                    owner.to_ptr.csignature if owner
                else
                    if return_type.basic_type?
                        return_type.csignature
                    else
                        return_type.to_single_ptr.csignature
                    end
                end
            paras = cparameters.map do |p|
                if p.type.basic_type?
                    p.csignature
                else
                    p.to_single_ptr.csignature
                end
            end.join(", ")
            cs = "#{cs} #{cname}(#{paras})"
            [s,cs]
        end

        def instance_method?
            owner.is_a?(RClass) && !constructor? && !static?
        end

        def cparameters
            return @cparameters if @cparameters
            if instance_method?
                p = RParameter.new("rbind_obj",owner)
                [p] +  @parameters
            else
                @parameters.dup
            end
        end

        def owner=(obj)
            super
            @base_class ||=obj
            @parameters.each do |para|
                para.owner = self
            end
            self
        end

        def constructor?
            !@return_type
        end

        # returns true if the method is a setter or getter
        # generated for a class attribute
        def attribute?
            false
        end

        def pretty_print(pp)
            if cname
                pp.text "#{signature} --> #{cname}"
            else
                pp.text signature
            end
        end
    end
end
