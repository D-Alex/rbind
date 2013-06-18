#ifndef <%= name %>
#define <%= name %>
<%= wrap_includes %>

#ifdef __cplusplus
extern "C"
{
#endif

// general rbind functions 
const char* rbindGetLastError();
bool rbindHasError();
void rbindClearError();

<%= wrap_operations %>

#ifdef __cplusplus
}
#endif
#endif
