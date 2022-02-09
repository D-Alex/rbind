module Rbind
    class StdMap < RTemplateClass
        def specialize(klass,parameters)
            if parameters.size < 2
                raise ArgumentError,"StdMap does require at least two template parameters. Got: #{parameters}}"
            end
            map_key_type = parameters.flatten[0]
            map_value_type = parameters.flatten[1]
            if parameters.size > 2
                map_comp_type = parameters.flatten[2]
            else
                map_comp_type = nil
            end

            klass.add_operation ROperation.new(klass.name,nil)
            klass.add_operation ROperation.new(klass.name,nil,RParameter.new("other",klass).to_const)

            klass.add_operation ROperation.new("size",type("size_t"))
            klass.add_operation ROperation.new("clear",type("void"))
            klass.add_operation ROperation.new("empty",type("bool"))
            klass.add_operation ROperation.new("operator[]",map_value_type, RParameter.new("key_type", map_key_type))
            klass.add_operation ROperation.new("at",map_value_type, RParameter.new("key_type",map_key_type))
            klass.add_operation ROperation.new("erase",type("void"), RParameter.new("key_type",map_key_type))

            klass.add_operation ROperation.new("getKeys",type("std::vector<#{map_key_type}>"))
            klass.operation("getKeys").overwrite_c do
		str = %{
		    auto keys = new std::vector<#{map_key_type}>();
		    std::transform(std::begin(*rbind_obj_), std::end(*rbind_obj_), std::back_inserter(*keys), 
				    [](std::pair<#{map_key_type},#{map_value_type}> const& pair) {
			    return pair.first;
			}); 
		    return toC(keys);
		}
	    end
	    klass
        end

        # called from RTemplate when ruby_specialize is called for the instance
        def specialize_ruby_specialization(klass)
            %Q$ 
            def to_hash
	        hash = Hash.new
	    	keys = get_keys
		keys.each do |k|
		    hash[k] = self[k]
		end
		hash
            end$
        end
    end
end
