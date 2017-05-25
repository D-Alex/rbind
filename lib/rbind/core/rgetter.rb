
module Rbind
    class RGetter < ROperation
        attr_reader :attribute

        def initialize(attr)
            @attribute = attr
	    super("get_#{attr.name}",attr.type.to_const)
        end

        def attribute?
            true
        end

        def signature
            attribute.signature
        end
    end
end
