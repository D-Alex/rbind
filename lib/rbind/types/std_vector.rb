module Rbind
    class StdVector < RTemplateClass
        def specialize(name,*parameters)
            if parameters.size != 1
                raise ArgumentError,"StdVector does only support one template parameter. Got: #{parameters}}"
            end

            klass = super
            vector_type = parameters.first

            klass.add_operation ROperation.new(klass.name,nil)
            klass.add_operation ROperation.new(klass.name,nil,RParameter.new("other",klass))

            para = Array.new
            para <<  RParameter.new("size",type("size_t"))
            para <<  RParameter.new("val",vector_type).default_value(vector_type.full_name)
            klass.add_operation ROperation.new("resize",type("void"),para)
            klass.add_operation ROperation.new("size",type("size_t"))
            klass.add_operation ROperation.new("capacity",type("size_t"))
            klass.add_operation ROperation.new("empty",type("bool"))
            klass.add_operation ROperation.new("reserve",type("void"),RParameter.new("size",type("size_t")))
            klass.add_operation ROperation.new("operator[]",vector_type,RParameter.new("size",type("size_t")))
            klass.add_operation ROperation.new("at",vector_type,RParameter.new("size",type("size_t")))
            klass.add_operation ROperation.new("front",vector_type)
            klass.add_operation ROperation.new("back",vector_type)
            klass.add_operation ROperation.new("data",type("void *"))
            klass.add_operation ROperation.new("push_back",type("void"),RParameter.new("other",vector_type))
            klass.add_operation ROperation.new("pop_back",type("void"))
            klass.add_operation ROperation.new("swap",type("void"),RParameter.new("other",klass).add_flag(:IO))
            klass
        end
    end
end
