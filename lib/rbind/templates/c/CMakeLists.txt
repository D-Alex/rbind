cmake_minimum_required(VERSION 2.6)
PROJECT(<%= library_name %> CXX)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(FindPkgConfig)
<%= find_packages %>
<%= find_gems%>
SET(RBIND_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/types.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/operations.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/conversions.cc")

add_custom_command(OUTPUT ${RBIND_SRC}
       COMMAND ruby "${CMAKE_CURRENT_SOURCE_DIR}/../rbind.rb")

ADD_LIBRARY(<%= library_name %> SHARED ${RBIND_SRC})
TARGET_LINK_LIBRARIES(<%= library_name %> <%= libs %> ${GEM_LIBRARIES})

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/rbind.pc.in ${CMAKE_CURRENT_BINARY_DIR}/<%= library_name %>.pc @ONLY)

set(ROOT_FOLDER ${CMAKE_CURRENT_SOURCE_DIR}/..)
if(GEM_INSTALL)
    # local install
    install(TARGETS <%= library_name %> LIBRARY DESTINATION ${ROOT_FOLDER}/lib/lib)
    install(FILES types.h operations.h conversions.hpp DESTINATION ${ROOT_FOLDER}/lib/include)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/extern.rbind DESTINATION ${ROOT_FOLDER}/lib/include)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/config.rbind DESTINATION ${ROOT_FOLDER}/lib/include)
else()
    # global install
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/<%= library_name %>.pc DESTINATION lib/pkgconfig)
    install(TARGETS <%= library_name %> LIBRARY DESTINATION lib)
    install(FILES types.h operations.h conversions.hpp DESTINATION include/${PROJECT_NAME})
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/extern.rbind DESTINATION include/${PROJECT_NAME})
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/config.rbind DESTINATION include/${PROJECT_NAME})

    FIND_PACKAGE(Ruby)
    IF(NOT RUBY_INCLUDE_PATH)
        MESSAGE(STATUS "Ruby library not found. Cannot install ruby extensions")
    ELSEIF(NOT RUBY_EXTENSIONS_AVAILABLE)
        STRING(REGEX REPLACE ".*lib(32|64)?/?" "lib/" RUBY_LIBRARY_INSTALL_DIR ${RUBY_RUBY_LIB_PATH})
        INSTALL(DIRECTORY ${ROOT_FOLDER}/lib/ruby DESTINATION ${RUBY_LIBRARY_INSTALL_DIR}
            FILES_MATCHING PATTERN "*.rb")
    ENDIF(NOT RUBY_INCLUDE_PATH)
endif()
