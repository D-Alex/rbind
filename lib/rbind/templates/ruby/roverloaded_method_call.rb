        # wrapper for <%= signature %>
        @@rbind_<%=name%>_sig_defaults ||= <%= signature_default_values %>
        if(args.size >= <%= min_number_of_parameters %> && args.size <= <%= parameters.size %>)
            args.size.upto(<%= parameters.size-1%>) do |i|
                args[i] = @@rbind_<%=name%>_sig_defaults[i]
            end
            begin
                <%- if !return_type || return_type.basic_type? || operator? -%>
                return Rbind::<%= cname %>(*args)
                <%- else -%>
                result = Rbind::<%= cname %>(*args)
                # store owner insight the pointer to not get garbage collected
                result.instance_variable_get(:@__obj_ptr__).instance_variable_set(:@__owner__,self) if !result.__owner__?
                return result
                <%- end -%>
            rescue TypeError => e
                @error = e
            end
        end
