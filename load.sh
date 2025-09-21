#!/bin/bash

# SPUD RISC-V Load Script
# Loads ELF files to FPGA without opening serial console

set -e  # Exit on any error

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo -e "${BLUE}SPUD RISC-V Load Script${NC}"
    echo "========================"
    echo ""
    echo "Usage:"
    echo "  ./load.sh <demo_name> [options]     - Load specific demo to FPGA"
    echo "  ./load.sh <elf_file> [options]      - Load specific ELF file to FPGA"
    echo "  ./load.sh help                      - Show this help"
    echo ""
    echo "Options:"
    echo "  -t <type>     Device type (uart|ftdi, default: uart)"
    echo "  -d <device>   Serial device (default: /dev/ttyUSB1)"
    echo "  -b <baud>     Baud rate (default: 1000000)"
    echo "  -p <args>     Program arguments string"
    echo ""
    echo "Examples:"
    echo "  ./load.sh hello_world"
    echo "  ./load.sh donut -d /dev/ttyUSB0"
    echo "  ./load.sh gpio_test -t ftdi -b 115200"
    echo "  ./load.sh ./path/to/custom.elf"
    echo "  ./load.sh hello_world -p \"arg1 arg2\""
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
SOC_RUN_DIR="./spud_riscv_soc/fpga/arty/run"

if [ ! -d "$RV32I_TOOLS_DIR" ]; then
    print_error "spud_rv32i-tools directory not found!"
    echo "Make sure you're running this script from the root of the repository."
    exit 1
fi

if [ ! -d "$SOC_RUN_DIR" ]; then
    print_error "SOC run directory not found at $SOC_RUN_DIR!"
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
shift  # Remove the first argument, leaving the rest for the load script

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

    print_info "Loading demo: $DEMO_NAME"
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

# Parse command line arguments for device settings
TYPE="uart"
DEVICE="/dev/ttyUSB1"
BAUD="1000000"
PROGARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t)
            TYPE="$2"
            shift 2
            ;;
        -d)
            DEVICE="$2"
            shift 2
            ;;
        -b)
            BAUD="$2"
            shift 2
            ;;
        -p)
            PROGARGS="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_info "Resetting target and loading to FPGA..."
echo ""

# Reset the target (poke)
echo "Resetting target..."
python3 "$SOC_RUN_DIR/poke.py" -t "$TYPE" -d "$DEVICE" -b "$BAUD" -a 0xF0000000 -v 0x0

# Load the ELF file
echo "Loading ELF file..."
python3 "$SOC_RUN_DIR/load.py" -t "$TYPE" -d "$DEVICE" -b "$BAUD" -f "$ELF_FILE" -p "$PROGARGS"

echo ""
print_success "Load completed! Program is ready to run."
print_info "To connect to serial console, use: screen $DEVICE $BAUD"