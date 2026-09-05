#!/usr/bin/env bash
# ==============================================================================
# Project: Apex MidEnd IVI - Automotive In-Vehicle Infotainment System
# Developer: Sk Rehan Ahamed
# File: runner.sh
# Description: Cross-Platform Build & Run Automation Helper
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}${CYAN}======================================================================${RESET}"
echo -e "${BOLD}${CYAN}  Apex MidEnd IVI - Automotive Digital Head Unit System${RESET}"
echo -e "${BOLD}${CYAN}  Developer: Sk Rehan Ahamed${RESET}"
echo -e "${BOLD}${CYAN}======================================================================${RESET}\n"

ACTION="${1:-run}"

case "$ACTION" in
    build)
        echo -e "${YELLOW}⚡ Building Apex MidEnd IVI...${RESET}"
        cmake -B build -S . -GNinja -DCMAKE_BUILD_TYPE=Release
        cmake --build build --parallel
        echo -e "${GREEN}✔ Build complete: build/ApexIVI${RESET}"
        ;;
    run)
        echo -e "${YELLOW}⚡ Building & Launching Apex MidEnd IVI (1280x720 Native)...${RESET}"
        cmake -B build -S . -GNinja -DCMAKE_BUILD_TYPE=Release
        cmake --build build --parallel
        echo -e "${GREEN}✔ Launching Viewport...${RESET}"
        ./build/ApexIVI
        ;;
    clean)
        echo -e "${YELLOW}🧹 Cleaning build directories...${RESET}"
        rm -rf build
        echo -e "${GREEN}✔ Clean complete.${RESET}"
        ;;
    help|*)
        echo "Usage: ./scripts/runner.sh [build | run | clean]"
        echo "  build : Configure and compile native binary"
        echo "  run   : Compile and launch native 1280x720 viewport"
        echo "  clean : Remove build directory and caches"
        ;;
esac
