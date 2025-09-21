#!/bin/bash

# SPUD RISC-V Build Script
# Builds demos using the rv32i tools Makefile

set -e  # Exit on any error

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo -e "${BLUE}SPUD RISC-V Build Script${NC}"
    echo "========================="
    echo ""
    echo "Usage:"
    echo "  ./build.sh <demo_name> [flags]     - Build specific demo"
    echo "  ./build.sh all [flags]             - Build all demos"
    echo "  ./build.sh clean                   - Clean all build artifacts"
    echo "  ./build.sh list                    - List available demos"
    echo "  ./build.sh help                    - Show this help"
    echo ""
    echo "Flags:"
    echo "  --sim-display             - Enable simulation display mode"
    echo "  --uart-display            - Enable UART display mode"
    echo ""
    echo "Environment variables (alternative to flags):"
    echo "  SIM_DISPLAY=1             - Enable simulation display mode"
    echo "  UART_DISPLAY=1            - Enable UART display mode"
    echo ""
    echo "Examples:"
    echo "  ./build.sh hello_world"
    echo "  ./build.sh hello_world --sim-display"
    echo "  ./build.sh donut --uart-display"
    echo "  ./build.sh all --sim-display --uart-display"
    echo "  SIM_DISPLAY=1 ./build.sh hello_world"
    echo "  UART_DISPLAY=1 ./build.sh donut"
}

print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_info() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if rv32i tools directory exists
RV32I_TOOLS_DIR="./spud_rv32i-tools"
if [ ! -d "$RV32I_TOOLS_DIR" ]; then
    print_error "spud_rv32i-tools directory not found!"
    echo "Make sure you're running this script from the root of the repository."
    exit 1
fi

# Check if Makefile exists
if [ ! -f "$RV32I_TOOLS_DIR/Makefile" ]; then
    print_error "Makefile not found in $RV32I_TOOLS_DIR!"
    exit 1
fi

# Parse flags and set environment variables
MAKE_FLAGS=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --sim-display)
            export SIM_DISPLAY=1
            MAKE_FLAGS="$MAKE_FLAGS SIM_DISPLAY=1"
            shift
            ;;
        --uart-display)
            export UART_DISPLAY=1
            MAKE_FLAGS="$MAKE_FLAGS UART_DISPLAY=1"
            shift
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Set back positional parameters
set -- "${ARGS[@]}"

# Show active flags if any are set
if [ -n "$MAKE_FLAGS" ]; then
    print_info "Active build flags:$MAKE_FLAGS"
fi

# Handle arguments
case "${1:-help}" in
    help|--help|-h)
        print_usage
        exit 0
        ;;
    list)
        print_info "Available demos in $RV32I_TOOLS_DIR:"
        cd "$RV32I_TOOLS_DIR"
        make list
        ;;
    clean)
        print_info "Cleaning build artifacts..."
        cd "$RV32I_TOOLS_DIR"
        make clean
        print_success "Clean completed!"
        ;;
    all)
        print_info "Building all demos..."
        cd "$RV32I_TOOLS_DIR"
        make $MAKE_FLAGS all
        print_success "All demos built successfully!"
        ;;
    check-toolchain)
        print_info "Checking RISC-V toolchain..."
        cd "$RV32I_TOOLS_DIR"
        make check-toolchain
        ;;
    *)
        DEMO="$1"
        print_info "Building demo: $DEMO"
        cd "$RV32I_TOOLS_DIR"

        # Check if demo exists first
        if [ ! -d "demos/$DEMO" ]; then
            print_error "Demo '$DEMO' not found!"
            echo ""
            echo "Available demos:"
            make list
            exit 1
        fi

        # Build the demo
        make $MAKE_FLAGS "$DEMO"
        print_success "Demo '$DEMO' built successfully!"

        # Show the generated files
        echo ""
        echo "Generated files:"
        echo "  ELF file: $RV32I_TOOLS_DIR/demos/$DEMO/build/$DEMO.elf"
        echo "  Binary:   $RV32I_TOOLS_DIR/demos/$DEMO/build/$DEMO.bin"
        echo "  Disasm:   $RV32I_TOOLS_DIR/demos/$DEMO/build/$DEMO.dis"
        ;;
esac