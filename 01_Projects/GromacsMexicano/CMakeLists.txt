cmake_minimum_required(VERSION 3.20)
project(GromacsMexicano_Phase4 LANGUAGES CXX CUDA)

# Set CUDA standard
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Disable architecture list to allow CUDA auto-detection
set(CMAKE_CUDA_ARCHITECTURES "86")

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# ===== PARSER EXECUTABLE (NEW) =====
add_executable(test_parser 
    src/test_parser.cpp
    src/GMXParser.cpp
)
target_compile_options(test_parser PRIVATE -O3 -Wall -std=c++17)

# ===== PHASE 5a: NEIGHBOR-LIST KERNEL VALIDATION TEST =====
add_executable(test_lista
    src/test_lista.cu
    src/lista_linkcell_cuda_streams.cu
)
target_link_libraries(test_lista PRIVATE m)
target_compile_options(test_lista PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:-O3>
    $<$<COMPILE_LANGUAGE:CXX>:-O3 -Wall>
)

# Source files for main phase4 project
set(SOURCES
    src/main.cu
    src/integrator.cu
    src/ewald_setup.cpp
    src/forces.cu
    src/io.cu
    src/copyParamsToGPU.cu
    src/cuda_streams_manager.cu
    src/cuda_streams_integration.cu
    src/fzas_lj_cuda_streams.cu
    src/kwald_cuda_streams.cu
    src/lista_linkcell_cuda_streams.cu
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
