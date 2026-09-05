# ==============================================================================
# Apex IVI - Qt6 C++ Native Automotive System
# Developer: Sk Rehan Ahamed
# ==============================================================================

.PHONY: all build run clean help

# Default target
all: build

# Build Qt6 C++ application with parallel compilation
build:
	@mkdir -p build
	@cmake -B build -S . -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/qt"
	@cmake --build build -j$(shell sysctl -n hw.ncpu 2>/dev/null || echo 4)
	@echo "⚡ Apex IVI build complete: build/ApexIVI"

# Run Apex IVI native head unit
run: build
	@echo "🚀 Launching Apex IVI (1280x720 Native)..."
	@./build/ApexIVI

# Clean build artifacts
clean:
	@rm -rf build
	@echo "🧹 Clean complete."

help:
	@echo "Apex IVI - Qt6 C++ Head Unit"
	@echo "  make build  - Compile the native C++ & QML binary"
	@echo "  make run    - Build and launch the native IVI window"
	@echo "  make clean  - Clean CMake build cache"
