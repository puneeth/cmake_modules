#
# A cmake module to locate and configure Apache Thrift
#
#   Copyright (C) 2013  Puneeth NS
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# ==============================================================================
#
# - Find Thrift
# Adapted from 
#   - https://github.com/anvie/Anspypher/blob/master/
#                                    cmake/FindThrift.cmake [Basic thrift]
#   - https://github.com/Kitware/CMake/blob/
#                                master/Modules/FindProtobuf.cmake [Cpp gen files]
#
# THRIFT_ROOT can be defined as an env variable to point
# location where thrift is built.
# Also make sure thrift compiler is also in the path.
#
# This module defines
#
# THRIFT_VERSION, version string 
# THRIFT_INCLUDE_DIR, where to find Thrift headers
# THRIFT_LIBS, Thrift libraries
# THRIFT_NB_LIBS, Thrift non blocking libraries
# THRIFT_FOUND
#
# ==============================================================================
#
# Example: [Found in Thrift v0.9.0 tutorial] 
# 
#  FIND_PACKAGE( Thrift REQUIRED )
#   
#  SET(THRIFT_FILES 
#      thrift/shared.thrift
#      thrift/tutorial.thrift
#  )
#  
#  THRIFT_GENERATE_CPP( THRIFT_GEN_SRCS THRIFT_GEN_HDRS ${THRIFT_FILES} )
#  #output dir of thrift 
#  SET( THRIFT_GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp )
#  
#  ADD_DEFINITIONS( -DHAVE_NETINET_IN_H -DHAVE_INTTYPES_H )
#  
#  #Add all the would be generated service files here.. 
#  SET ( THRIFT_SERVICE_FILES ) 
#  LIST( APPEND  THRIFT_SERVICE_FILES "${THRIFT_GEN_DIR}/Calculator.cpp"  )
#  LIST( APPEND  THRIFT_SERVICE_FILES "${THRIFT_GEN_DIR}/SharedService.cpp"  )
#  SET_SOURCE_FILES_PROPERTIES( ${THRIFT_SERVICE_FILES} PROPERTIES GENERATED TRUE )
#  
#  INCLUDE_DIRECTORIES(
#    ${THRIFT_INCLUDE_DIR}
#    ${THRIFT_GEN_DIR}    
#  )
#  
#  ADD_EXECUTABLE(
#      server
#      ${THRIFT_GEN_SRCS}
#      ${THRIFT_GEN_HDRS}
#      src/CppServer.cpp
#      ${THRIFT_SERVICE_FILES}
#  )
#  
# TARGET_LINK_LIBRARIES(
#    server
#    ${THRIFT_LIBS}
#  ) 
#  
# ==============================================================================

function( THRIFT_GENERATE_CPP SRCS HDRS )
  if(NOT ARGN)
      message(SEND_ERROR "Error: THRIFT_GENERATE_CPP() called without any thrift files")
    return()
  endif()

  if(THRIFT_GENERATE_CPP_APPEND_PATH)
    # Create an include path for each file specified
    foreach(FIL ${ARGN})
      get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
      get_filename_component(ABS_PATH ${ABS_FIL} PATH)
      list(FIND _thrift_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _thrift_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  else()
    set(_thrift_include_path -I ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  if(DEFINED THRIFT_IMPORT_DIRS)
      foreach(DIR ${THRIFT_IMPORT_DIRS})
      get_filename_component(ABS_PATH ${DIR} ABSOLUTE)
      list(FIND _thrift_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _thrift_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  endif()

  set(${SRCS})
  set(${HDRS})
  foreach(FIL ${ARGN})
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
    get_filename_component(FIL_WE ${FIL} NAME_WE)

    list(APPEND ${SRCS} "${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/${FIL_WE}_types.cpp")
    list(APPEND ${HDRS} "${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/${FIL_WE}_types.h")
    list(APPEND ${SRCS} "${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/${FIL_WE}_constants.cpp")
    list(APPEND ${HDRS} "${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/${FIL_WE}_constants.h")

    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/${FIL_WE}_types.cpp"
             "${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/${FIL_WE}_types.h"
             "${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/${FIL_WE}_constants.cpp"
             "${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/${FIL_WE}_constants.h"
      COMMAND thrift
      ARGS -o ${CMAKE_CURRENT_BINARY_DIR} --gen cpp ${ABS_FIL}
      DEPENDS ${ABS_FIL}
      COMMENT "Running C++ thrift compiler on ${FIL}"
      VERBATIM )
  endforeach()

  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)

endfunction()

EXEC_PROGRAM(thrift ARGS -version OUTPUT_VARIABLE THRIFT_VERSION
RETURN_VALUE Thrift_RETURN)

FIND_PATH(THRIFT_INCLUDE_DIR Thrift.h PATHS
    /usr/local/include/thrift
    /opt/local/include/thrift
    $ENV{THRIFT_ROOT}/include/thrift
)

SET(Thrift_LIB_PATHS 
    /usr/local/lib 
    /opt/local/lib
    $ENV{THRIFT_ROOT}/lib
)

FIND_LIBRARY(THRIFT_LIB NAMES thrift PATHS ${Thrift_LIB_PATHS})
FIND_LIBRARY(THRIFT_NB_LIB NAMES thriftnb PATHS ${Thrift_LIB_PATHS})

SET( THRIFT_INCLUDE_DIRS ${THRIFT_INCLUDE_DIR} )
SET( THRIFT_LIBS ${THRIFT_LIB} )
SET( THRIFT_NB_LIBS ${THRIFT_NB_LIB} )

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments
find_package_handle_standard_args(Thrift FOUND_VAR THRIFT_FOUND
                                         REQUIRED_VARS THRIFT_LIB THRIFT_NB_LIB THRIFT_INCLUDE_DIR
                                         VERSION_VAR THRIFT_VERSION)

MARK_AS_ADVANCED(
 THRIFT_LIB
 THRIFT_NB_LIB
 THRIFT_INCLUDE_DIR
)
