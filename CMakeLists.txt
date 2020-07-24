cmake_minimum_required(VERSION 3.10)

project(Ganlib)

# for homebrew installation
if (NOT ENV{FC} AND APPLE)
    set(ENV{FC} "/usr/local/bin/gfortran")
endif ()

enable_language(Fortran)

# identify os architecture
execute_process(
        COMMAND uname -sm
        COMMAND sed "s/[ ]/_/"
        COMMAND tr -d "\n"
        OUTPUT_VARIABLE OS_ARCHITECTURE)

message("OS ARCH: ${OS_ARCHITECTURE}")
message("Fortran: ${CMAKE_Fortran_COMPILER}")
message("C: ${CMAKE_C_COMPILER}")
message("CXX: ${CMAKE_CXX_COMPILER}")

if ("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
    MESSAGE("++ 64 bit architecture")
    set(NBIT "-m64")
else ()
    MESSAGE("++ 32 bit architecture")
    set(NBIT "-m32")
endif ()

# get all source files
file(GLOB GANLIB_SRC_FILES
        "src/*.f"
        "src/*.f90"
        "src/*.F"
        "src/*.F90"
        "src/*.h"
        "src/*.c"
        )

# remove main file from the list
list(REMOVE_ITEM GANLIB_SRC_FILES "${CMAKE_CURRENT_SOURCE_DIR}/src/GANMAIN.f90")

# separate f77 files to add special flags.
file(GLOB F77_SRC_FILES "src/*.f")

if (CMAKE_Fortran_COMPILER_ID MATCHES GNU)
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -Wall ${NBIT} -fPIC")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall ${NBIT} -fPIC")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${NBIT}")
    set_source_files_properties(${F77_SRC_FILES} PROPERTIES COMPILE_FLAGS -frecord-marker=4)
    message("LFLAGS: ${CMAKE_EXE_LINKER_FLAGS}")
    message("FFLAGS: ${CMAKE_Fortran_FLAGS}")
    message("CFLAGS: ${CMAKE_C_FLAGS}")
endif ()

# set(CMAKE_BUILD_TYPE Debug)
# set(CMAKE_BUILD_TYPE Release)
message("CMAKE_BUILD_TYPE = ${CMAKE_BUILD_TYPE}")

# Create static library
add_library(lib STATIC ${GANLIB_SRC_FILES})
set_target_properties(lib PROPERTIES
        LINKER_LANGUAGE Fortran
        OUTPUT_NAME Ganlib
        ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib/${OS_ARCHITECTURE}
        Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib/${OS_ARCHITECTURE}/modules
        )

# Create binary
add_executable(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/src/GANMAIN.f90)
set_target_properties(${PROJECT_NAME} PROPERTIES
        LINKER_LANGUAGE Fortran
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin/${OS_ARCHITECTURE}
        Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib/${OS_ARCHITECTURE}/modules
        )
target_link_libraries(${PROJECT_NAME} lib)
