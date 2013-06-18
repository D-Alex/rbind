#ifndef <%= name %>
#define <%= name %>

#include <cstddef>
<%= wrap_includes %>

#ifdef __cplusplus
extern "C"
{
#endif

<%= wrap_types%>

#ifdef __cplusplus
}
#endif
#endif
