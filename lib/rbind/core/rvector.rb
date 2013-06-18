module Rbind
    class RVector < RStruct
        def initialize(name,root,type)
            @vector_type = type
            super(name)
            add_operation ROperation.new(self.name,nil)
            add_operation ROperation.new(self.name,nil,RParameter.new("other",self))

            para = Array.new
            para <<  RParameter.new("size",root.type("size_t"))
            para <<  RParameter.new("val",type).default_value(type.full_name)
            add_operation ROperation.new("resize",root.type("void"),para)
            add_operation ROperation.new("size",root.type("size_t"))
            add_operation ROperation.new("capacity",root.type("size_t"))
            add_operation ROperation.new("empty",root.type("bool"))
            add_operation ROperation.new("reserve",root.type("void"),RParameter.new("size",root.type("size_t")))
            add_operation ROperation.new("operator[]",type,RParameter.new("size",root.type("size_t")))
            add_operation ROperation.new("at",type,RParameter.new("size",root.type("size_t")))
            add_operation ROperation.new("front",type)
            add_operation ROperation.new("back",type)
            add_operation ROperation.new("data",root.type("void *"))
            add_operation ROperation.new("push_back",root.type("void"),RParameter.new("other",type))
            add_operation ROperation.new("pop_back",root.type("void"))
            add_operation ROperation.new("swap",root.type("void"),RParameter.new("other",self).add_flag(:IO))
        end
    end
end
