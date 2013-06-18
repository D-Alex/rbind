cmake_minimum_required(VERSION 2.6)

PROJECT(<%= library_name %> CXX)

include(FindPkgConfig)
<%= find_packages %>

SET(RBIND_SRC types.cc operations.cc conversions.cc)
ADD_LIBRARY(<%= library_name %> SHARED ${RBIND_SRC})

TARGET_LINK_LIBRARIES(<%= library_name %> <%= libs %>)
