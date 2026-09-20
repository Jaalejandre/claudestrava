# Makefile for Phase 5 GPU Optimization
# Project: GromacsMexicano Phase 5
# CUDA Compilation for GPU-accelerated molecular dynamics

CC := nvcc
CXX := g++
CXXFLAGS := -std=c++11 -Wall -Wextra -O3
NVCCFLAGS := -arch=sm_80 -O3 -std=c++11 -Xcompiler -Wall -Xcompiler -Wextra
LDFLAGS := -lcuda -lcudart -lm

# Directories
SRC_DIR := src
BUILD_DIR := build
BIN_DIR := bin

# Source files
CUDA_SOURCES := $(SRC_DIR)/phase5_main.cu \
                $(SRC_DIR)/phase5_fuerzas_kernel.cu \
                $(SRC_DIR)/phase5_lista_kernel.cu

HEADERS := $(SRC_DIR)/phase5_config.h

# Object files
CUDA_OBJECTS := $(patsubst $(SRC_DIR)/%.cu,$(BUILD_DIR)/%.o,$(CUDA_SOURCES))

# Target executable
TARGET := $(BIN_DIR)/phase5_gpu_sim

# Default target
.PHONY: all
all: $(TARGET)

# Create directories
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

# CUDA object compilation
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cu $(HEADERS) | $(BUILD_DIR)
	@echo "Compiling CUDA: $<"
	$(CC) $(NVCCFLAGS) -c $< -o $@

# Linking
$(TARGET): $(CUDA_OBJECTS) | $(BIN_DIR)
	@echo "Linking: $@"
	$(CC) $(NVCCFLAGS) $(CUDA_OBJECTS) -o $(TARGET) $(LDFLAGS)
	@echo "✓ Build successful: $(TARGET)"

# Clean targets
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR) $(BIN_DIR)
	@echo "✓ Clean complete"

# Run executable
.PHONY: run
run: $(TARGET)
	@echo "Running Phase 5 GPU Simulation..."
	./$(TARGET)

# Help target
.PHONY: help
help:
	@echo "Phase 5 GPU Optimization - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all     - Build the Phase 5 GPU executable (default)"
	@echo "  run     - Build and run the executable"
	@echo "  clean   - Remove build artifacts"
	@echo "  help    - Display this help message"
	@echo ""
	@echo "Configuration:"
	@echo "  CUDA Architecture: sm_80 (RTX 30/40 series)"
	@echo "  C++ Standard: C++11"
	@echo "  Optimization Level: O3"
	@echo ""
	@echo "Source files:"
	@echo "  $(CUDA_SOURCES)"

.PHONY: info
info:
	@echo "Build Configuration:"
	@echo "  CC: $(CC)"
	@echo "  CXXFLAGS: $(CXXFLAGS)"
	@echo "  NVCCFLAGS: $(NVCCFLAGS)"
	@echo "  LDFLAGS: $(LDFLAGS)"
	@echo ""
	@echo "Source files:"
	@for src in $(CUDA_SOURCES); do echo "  $$src"; done
	@echo ""
	@echo "Header files:"
	@for hdr in $(HEADERS); do echo "  $$hdr"; done
