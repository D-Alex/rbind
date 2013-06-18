    # wrapper for <%= signature %>
    def <%=name%>(<%= wrap_parameters_signature %>)
    <%- if return_type.basic_type? || operator? -%>
        Rbind::<%= cname %>( <%= wrap_parameters_call %>)
    <%- else -%>
        result = Rbind::<%= cname %>( <%= wrap_parameters_call %>)
        # store owner insight the pointer to not get garbage collected
        result.instance_variable_get(:@__obj_ptr__).instance_variable_set(:@__owner__,self) if !result.__owner__?
        result
    <%- end -%>
    end

