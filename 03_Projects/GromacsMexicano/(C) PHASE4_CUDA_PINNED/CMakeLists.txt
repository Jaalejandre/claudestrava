cmake_minimum_required(VERSION 3.20)
project(DM UAMI_Phase4 LANGUAGES CXX CUDA)

# Set CUDA standard
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Disable architecture list to allow CUDA auto-detection
set(CMAKE_CUDA_ARCHITECTURES OFF)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Source files
set(SOURCES
    src/main.cu
    src/integrator.cu
    src/forces.cu
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
