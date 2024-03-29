// operation wrapper for <%= attribute? ? "#{owner.full_name}.#{attribute.name}" : signature %>
<%= csignature %>
{
    try
    {
        <%= wrap_parameters %><%= wrap_call %>
    }
    catch(std::exception &error){strncpy(&last_error_message[0],error.what(),254);}
    catch(...){strncpy(&last_error_message[0],"Unknown Exception",254);}
    <%- if !return_type || return_type.ptr? || !return_type.basic_type? -%>
    return NULL;
    <%- elsif return_type.ref? -%>
    static <%= return_type.cname %> invalid;
    return invalid;
    <%- elsif return_type.name != "void"  -%>
    return (<%= return_type.cname %>) <%= return_type.invalid_value %>;
    <%- end -%>
}
