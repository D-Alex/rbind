
module Rbind
    class RCastOperation < ROperation
        extend ::Rbind::Logger
        def initialize(name,to_class,from_class=nil)
            para = []
            if(from_class)
                @static = true
                para << RParameter.new("ptr",from_class.to_ptr)
            end
            super(name,to_class.to_ptr,para)
        end
    end
end
