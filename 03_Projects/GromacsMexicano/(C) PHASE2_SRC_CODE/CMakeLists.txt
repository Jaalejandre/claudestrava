cmake_minimum_required(VERSION 3.20)
project(DM UAMI_CPP VERSION 3.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -march=native -fPIC")

# OpenMP (paralelización)
find_package(OpenMP REQUIRED)

# Archivos fuente
set(SOURCES
    src/main.cpp
    src/io.cpp
    src/forces.cpp
    src/integrator.cpp
    src/neighbor.cpp
    src/ewald.cpp
)

# Headers
include_directories(${CMAKE_SOURCE_DIR}/include)

# Executable
add_executable(dm_mx_npt ${SOURCES})

# Link libraries
target_link_libraries(dm_mx_npt
    PUBLIC OpenMP::OpenMP_CXX
    PUBLIC m
)

# Compilador flags
if(MSVC)
    target_compile_options(dm_mx_npt PRIVATE /W4 /O2)
else()
    target_compile_options(dm_mx_npt PRIVATE -Wall -Wextra -O3)
endif()

# Output
set_target_properties(dm_mx_npt PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "OpenMP: ${OPENMP_FOUND}")
