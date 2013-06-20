cmake_minimum_required(VERSION 2.6)
PROJECT(<%= library_name %> CXX)

include(FindPkgConfig)
<%= find_packages %>

SET(RBIND_SRC types.cc operations.cc conversions.cc)
ADD_LIBRARY(<%= library_name %> SHARED ${RBIND_SRC})

TARGET_LINK_LIBRARIES(<%= library_name %> <%= libs %>)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/rbind.pc.in ${CMAKE_CURRENT_BINARY_DIR}/<%= library_name %>.pc @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/<%= library_name %>.pc DESTINATION lib/pkgconfig)

install(TARGETS <%= library_name %> LIBRARY DESTINATION lib)
install(FILES types.h operations.h conversions.hpp DESTINATION include/${PROJECT_NAME}/${DIR})

if (EXISTS ${PROJECT_SOURCE_DIR}/extern.rbind)
    install(FILES ${PROJECT_SOURCE_DIR}/extern.rbind DESTINATION include/${PROJECT_NAME}/${DIR})
endif()

if (EXISTS ${PROJECT_SOURCE_DIR}/config.rbind)
    install(FILES ${PROJECT_SOURCE_DIR}/config.rbind DESTINATION include/${PROJECT_NAME}/${DIR})
endif()
