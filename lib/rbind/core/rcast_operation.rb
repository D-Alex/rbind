
module Rbind
    class RCastOperation < ROperation
        extend ::Rbind::Logger
        def initialize(name,to_class,from_class=nil)
            para = []
            if(from_class)
                @static = true
                para << RParameter.new("ptr",from_class.to_ptr)
            end
	    para << RParameter.new("parse_ownership",to_class.type("bool"))
            super(name,to_class.to_ptr,para)
        end
    end
end
