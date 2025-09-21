#!/bin/bash

# SPUD RISC-V Run Script
# Runs ELF files on FPGA using the SOC run.py script

set -e  # Exit on any error

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo -e "${BLUE}SPUD RISC-V Run Script${NC}"
    echo "======================"
    echo ""
    echo "Usage:"
    echo "  ./run.sh <demo_name> [options]     - Run specific demo on FPGA"
    echo "  ./run.sh <elf_file> [options]      - Run specific ELF file on FPGA"
    echo "  ./run.sh help                      - Show this help"
    echo ""
    echo "Options (passed to run.py):"
    echo "  -t <type>     Device type (uart|ftdi, default: uart)"
    echo "  -d <device>   Serial device (default: /dev/ttyUSB1)"
    echo "  -b <baud>     Baud rate (default: 1000000)"
    echo "  -p <args>     Program arguments string"
    echo ""
    echo "Examples:"
    echo "  ./run.sh hello_world"
    echo "  ./run.sh donut -d /dev/ttyUSB0"
    echo "  ./run.sh gpio_test -t ftdi -b 115200"
    echo "  ./run.sh ./path/to/custom.elf"
    echo "  ./run.sh hello_world -p \"arg1 arg2\""
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

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

# Check if required directories exist
RV32I_TOOLS_DIR="./spud_rv32i-tools"
SOC_RUN_SCRIPT="./spud_riscv_soc/fpga/arty/run.py"

if [ ! -d "$RV32I_TOOLS_DIR" ]; then
    print_error "spud_rv32i-tools directory not found!"
    echo "Make sure you're running this script from the root of the repository."
    exit 1
fi

if [ ! -f "$SOC_RUN_SCRIPT" ]; then
    print_error "SOC run script not found at $SOC_RUN_SCRIPT!"
    echo "Make sure the spud_riscv_soc submodule is properly initialized."
    exit 1
fi

# Handle help
if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ $# -eq 0 ]; then
    print_usage
    exit 0
fi

# Get the first argument (demo name or ELF file)
TARGET="$1"
shift  # Remove the first argument, leaving the rest for run.py

# Determine if TARGET is a demo name or an ELF file path
if [ -f "$TARGET" ]; then
    # TARGET is a file path
    ELF_FILE="$TARGET"
    print_info "Using ELF file: $ELF_FILE"
elif [ "${TARGET%.elf}" != "$TARGET" ]; then
    # TARGET ends with .elf, treat as file path
    ELF_FILE="$TARGET"
    if [ ! -f "$ELF_FILE" ]; then
        print_error "ELF file not found: $ELF_FILE"
        exit 1
    fi
    print_info "Using ELF file: $ELF_FILE"
else
    # TARGET is a demo name
    DEMO_NAME="$TARGET"
    ELF_FILE="$RV32I_TOOLS_DIR/demos/$DEMO_NAME/build/$DEMO_NAME.elf"

    # Check if demo exists
    if [ ! -d "$RV32I_TOOLS_DIR/demos/$DEMO_NAME" ]; then
        print_error "Demo '$DEMO_NAME' not found!"
        echo ""
        echo "Available demos:"
        cd "$RV32I_TOOLS_DIR"
        make list
        exit 1
    fi

    # Check if ELF file exists, build if necessary
    if [ ! -f "$ELF_FILE" ]; then
        print_warning "ELF file not found for demo '$DEMO_NAME'. Building now..."
        cd "$RV32I_TOOLS_DIR"
        make "$DEMO_NAME"
        cd - > /dev/null
        print_success "Demo '$DEMO_NAME' built successfully!"
    fi

    print_info "Running demo: $DEMO_NAME"
    print_info "Using ELF file: $ELF_FILE"
fi

# Verify ELF file exists
if [ ! -f "$ELF_FILE" ]; then
    print_error "ELF file not found: $ELF_FILE"
    exit 1
fi

# Convert ELF_FILE to absolute path if it's relative
if [ "${ELF_FILE:0:1}" != "/" ]; then
    ELF_FILE="$(pwd)/$ELF_FILE"
fi

print_info "Uploading and running on FPGA..."
echo ""

# Run the SOC script with the ELF file and any additional arguments
python3 "$SOC_RUN_SCRIPT" -f "$ELF_FILE" "$@"

echo ""
print_success "Run completed!"