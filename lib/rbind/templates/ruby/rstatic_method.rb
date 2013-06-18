    # wrapper for <%= signature %>
    def self.<%= name %>(<%= wrap_parameters_signature %>)
        Rbind::<%= cname %>(<%= wrap_parameters_call %>)
    end

