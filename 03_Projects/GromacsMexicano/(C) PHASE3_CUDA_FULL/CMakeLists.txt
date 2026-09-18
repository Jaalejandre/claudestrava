cmake_minimum_required(VERSION 3.20)
project(DM UAMI_CUDA_Phase3 VERSION 3.0 LANGUAGES CXX CUDA)

# C++ and CUDA standards
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_ARCHITECTURES 75)  # Adjust for your GPU (e.g., 75 for T4, 80 for A100)

# Optimization flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -march=native -fPIC")
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -O3 -Xptxas -O3 --use_fast_math")

# Find packages
find_package(CUDA REQUIRED)
find_package(OpenMP REQUIRED)

# Source files
set(SOURCES
    src/main.cpp
    src/forces_pairwise.cu
    src/forces_bonded.cu
    src/neighbor.cu
)

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include)
include_directories(${CUDA_INCLUDE_DIRS})

# Create executable
add_executable(dm_mx_npt_phase3 ${SOURCES})

# Link libraries
target_link_libraries(dm_mx_npt_phase3
    PUBLIC ${CUDA_LIBRARIES}
    PUBLIC OpenMP::OpenMP_CXX
    PUBLIC m
)

# Compiler-specific options
if(MSVC)
    target_compile_options(dm_mx_npt_phase3 PRIVATE /W4 /O2)
else()
    target_compile_options(dm_mx_npt_phase3 PRIVATE -Wall -Wextra -O3)
endif()

# Set properties
set_target_properties(dm_mx_npt_phase3 PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    CUDA_SEPARABLE_COMPILATION ON
)

# Build info
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "CUDA Found: ${CUDA_FOUND}")
message(STATUS "CUDA Toolkit Version: ${CUDA_VERSION}")
message(STATUS "CUDA Libraries: ${CUDA_LIBRARIES}")
message(STATUS "OpenMP: ${OPENMP_FOUND}")
message(STATUS "CXX Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "CUDA Standard: ${CMAKE_CUDA_STANDARD}")
