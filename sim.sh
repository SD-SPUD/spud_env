#!/bin/bash

# SPUD RISC-V Simulation Script
# Runs ELF files on Verilator testbench with VCD generation

set -e  # Exit on any error

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo -e "${BLUE}SPUD RISC-V Simulation Script${NC}"
    echo "=============================="
    echo ""
    echo "Usage:"
    echo "  ./sim.sh <demo_name> [vcd_name] [options]    - Run specific demo on Verilator"
    echo "  ./sim.sh <elf_file> [vcd_name] [options]     - Run specific ELF file on Verilator"
    echo "  ./sim.sh help                                - Show this help"
    echo ""
    echo "Arguments:"
    echo "  demo_name/elf_file    Demo name or path to ELF file"
    echo "  vcd_name              VCD output filename (optional, default: sysc_wave)"
    echo ""
    echo "Options (passed to test.x):"
    echo "  -f filename.elf      Executable to load (auto-set)"
    echo "  -t [0/1]             Enable program trace"
    echo "  -v 0xX               Trace Mask"
    echo "  -c nnnn              Max instructions to execute"
    echo "  -r 0xnnnn            Stop at PC address"
    echo "  -e 0xnnnn            Trace from PC address"
    echo "  -b 0xnnnn            Memory base address (default: 0x80000000)"
    echo "  -s nnnn              Memory size"
    echo "  -p dumpfile.bin      Post simulation memory dump file"
    echo "  -j sym_name          Symbol for memory dump start"
    echo "  -k sym_name          Symbol for memory dump end"
    echo ""
    echo "Examples:"
    echo "  ./sim.sh hello_world"
    echo "  ./sim.sh donut donut_waves"
    echo "  ./sim.sh hello_world hello_trace -t 1"
    echo "  ./sim.sh ./path/to/custom.elf custom_sim"
    echo "  ./sim.sh donut donut_test -b 0x80000000 -c 1000000"
    echo ""
    echo "VCD files will be created in spud_riscv_soc/tb/ directory"
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
TB_DIR="./spud_riscv_soc/tb"
TESTBENCH="$TB_DIR/build/test.x"

if [ ! -d "$RV32I_TOOLS_DIR" ]; then
    print_error "spud_rv32i-tools directory not found!"
    echo "Make sure you're running this script from the root of the repository."
    exit 1
fi

if [ ! -d "$TB_DIR" ]; then
    print_error "Testbench directory not found at $TB_DIR!"
    echo "Make sure the spud_riscv_soc submodule is properly initialized."
    exit 1
fi

if [ ! -f "$TESTBENCH" ]; then
    print_error "Testbench executable not found at $TESTBENCH!"
    echo "You may need to build the testbench first:"
    echo "  cd spud_riscv_soc/tb && make"
    exit 1
fi

# Handle help
if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ $# -eq 0 ]; then
    print_usage
    exit 0
fi

# Get the first argument (demo name or ELF file)
TARGET="$1"
shift  # Remove the first argument

# Get VCD name if provided (second argument if it doesn't start with -)
VCD_NAME="sysc_wave"
if [ $# -gt 0 ] && [ "${1:0:1}" != "-" ]; then
    VCD_NAME="$1"
    shift
fi

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

print_info "VCD output file: $VCD_NAME.vcd"
print_info "Starting Verilator simulation..."
echo ""

# Change to testbench directory
cd "$TB_DIR"

# Set default memory base if not provided
BASE_ARG=""
if [[ ! "$*" =~ -b ]]; then
    BASE_ARG="-b 0x80000000"
fi

# Run the testbench with VCD name, ELF file, and any additional arguments
./build/test.x --vcd_name "$VCD_NAME" -f "$ELF_FILE" $BASE_ARG "$@"

echo ""
print_success "Simulation completed!"
print_info "VCD file created: $TB_DIR/$VCD_NAME.vcd"
print_info "You can view it with: gtkwave $TB_DIR/$VCD_NAME.vcd"