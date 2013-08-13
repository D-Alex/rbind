<%= add_doc -%>
    # @note wrapper for <%= signature %>
    def self.<%= name %>(<%= wrap_parameters_signature %>)
<%= add_specialize_ruby -%>
        Rbind::<%= cname %>(<%= wrap_parameters_call %>)
    end
<%= add_alias -%>

