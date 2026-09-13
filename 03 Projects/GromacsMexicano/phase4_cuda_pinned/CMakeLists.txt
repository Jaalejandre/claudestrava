cmake_minimum_required(VERSION 3.20)
project(GromacsMexicano_Phase4 LANGUAGES CXX CUDA)

# Set CUDA standard
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Disable architecture list to allow CUDA auto-detection
set(CMAKE_CUDA_ARCHITECTURES OFF)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# ===== PARSER EXECUTABLE (NEW) =====
add_executable(test_parser 
    src/test_parser.cpp
    src/GMXParser.cpp
)
target_compile_options(test_parser PRIVATE -O3 -Wall -std=c++17)

# Source files for main phase4 project
set(SOURCES
    src/main.cu
    src/integrator.cu
    src/forces.cu
    src/io.cu
    src/GMXParser.cpp
    src/gromacs_loader.cpp
)

# Create executable
add_executable(phase4_cuda ${SOURCES})

# Link math library
target_link_libraries(phase4_cuda PRIVATE m)

# Compiler flags
target_compile_options(phase4_cuda PRIVATE 
    $<$<COMPILE_LANGUAGE:CUDA>:-O3>
    $<$<COMPILE_LANGUAGE:CXX>:-O3 -Wall>
)

message(STATUS "Phase 4 project configured successfully")
message(STATUS "Parser target: test_parser (C++17)")
