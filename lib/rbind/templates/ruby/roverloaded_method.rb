<%= add_doc -%>
    # @note wrapper for overloaded method <%= name %>
    def <%=name%>(*args)
<%= add_methods %>
        raise ArgumentError, "No overloaded signature fits to: #{args.map(&:class)}"
    end
<%= add_alias -%>

