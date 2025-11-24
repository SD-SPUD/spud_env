# SPUD Environment

Development environment for the SPUD RISC-V project. This repository provides a unified workspace for building, simulating, and running RISC-V programs on the SPUD SoC (System-on-Chip) using FPGA hardware or Verilator simulation.

## Overview

The SPUD environment consists of:
- **spud_riscv_soc** - A RISC-V RV32IM SoC with Timer, UART, SPI, and GPIO peripherals
- **spud_rv32i-tools** - SpudKit library and demo applications for RISC-V development
- **Convenience scripts** - Tools to simplify building, loading, running, and simulating programs

## Quick Start

### Prerequisites

1. **RISC-V Toolchain** - Required for building programs
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install gcc-riscv64-unknown-elf
   ```

2. **For Hardware (FPGA)**:
   - Digilent Artix-7 Arty FPGA board
   - Python 3 with serial support
   - Bitstream loaded on FPGA

3. **For Simulation**:
   - Verilator
   - SystemC
   - libelf

### Initial Setup

Clone with submodules:
```bash
git clone --recursive <repository-url>
cd spud_env
```

If you already cloned without `--recursive`:
```bash
git submodule update --init --recursive
```

### Building Programs

Use the `build.sh` script to compile demos:

```bash
# Build a specific demo
./build.sh hello_world

# Build with display modes
./build.sh display_demo --sim-display    # Terminal display for simulation
./build.sh display_demo --uart-display   # UART display for hardware

# Build all demos
./build.sh all

# List available demos
./build.sh list

# Clean build artifacts
./build.sh clean
```

**Available Demos:**
- `hello_world` - Basic UART output
- `gpio_test` - GPIO peripheral testing
- `display_demo` - 64x64 graphics with animations
- `donut` - 3D rotating donut animation

### Running on Hardware (FPGA)

Use `run.sh` to upload and execute programs on the FPGA:

```bash
# Run a demo (builds automatically if needed)
./run.sh hello_world

# Run with custom serial device
./run.sh donut -d /dev/ttyUSB0

# Run with different device type
./run.sh gpio_test -t ftdi -b 115200

# Run custom ELF file
./run.sh ./path/to/program.elf
```

**Options:**
- `-t <type>` - Device type: `uart` (default) or `ftdi`
- `-d <device>` - Serial device (default: `/dev/ttyUSB1`)
- `-b <baud>` - Baud rate (default: `1000000`)
- `-p <args>` - Program arguments string

### Loading Without Running

Use `load.sh` to upload programs without opening the serial console:

```bash
# Load a demo to FPGA
./load.sh hello_world

# Load with custom options
./load.sh donut -d /dev/ttyUSB0 -b 1000000
```

After loading, connect manually:
```bash
screen /dev/ttyUSB1 1000000
```

### Simulation with Verilator

Use `sim.sh` to run programs in the Verilator testbench:

```bash
# Run simulation
./sim.sh hello_world

# Run with custom VCD name
./sim.sh donut donut_waves

# Run with trace enabled
./sim.sh hello_world hello_trace -t 1

# Run with instruction limit
./sim.sh donut donut_test -c 1000000
```

**Simulation Options:**
- `-t [0/1]` - Enable program trace
- `-v 0xX` - Trace mask
- `-c nnnn` - Max instructions to execute
- `-r 0xnnnn` - Stop at PC address
- `-e 0xnnnn` - Trace from PC address
- `-b 0xnnnn` - Memory base address (default: 0x80000000)
- `-s nnnn` - Memory size
- `-p file.bin` - Post-simulation memory dump

VCD files are created in `spud_riscv_soc/tb/` and can be viewed with:
```bash
gtkwave spud_riscv_soc/tb/<vcd_name>.vcd
```

## Project Structure

```
spud_env/
├── spud_riscv_soc/          # RISC-V SoC HDL and testbench
│   ├── core/                 # RISC-V RV32IM CPU core
│   ├── soc/                  # Peripheral modules (UART, GPIO, Timer, SPI)
│   ├── fpga/arty/            # FPGA project for Arty board
│   └── tb/                   # Verilator testbench
├── spud_rv32i-tools/        # Development tools and demos
│   ├── spudkit/              # SpudKit library (drivers, display engine)
│   └── demos/                # Example programs
├── build.sh                 # Build script for demos
├── run.sh                   # Run on FPGA hardware
├── load.sh                  # Load to FPGA (no console)
└── sim.sh                   # Verilator simulation
```

## SpudKit Library

The SpudKit library provides:
- **Display Engine** - 64x64 framebuffer with drawing primitives
- **Peripheral Drivers** - UART, GPIO, Timer, SPI, IRQ
- **Dual Display Modes** - Terminal simulation and UART hardware output
- **Utilities** - Random numbers, string ops, math functions

Include in your programs:
```c
#include "spudkit.h"
```

## Hardware Specifications

**RISC-V Core:**
- Architecture: RV32IM (32-bit with integer multiply/divide)
- 16KB instruction cache (8KB x 2-way)

**Memory Map:**
| Address Range | Peripheral |
|---------------|------------|
| 0x8000_0000 - 0x8fff_ffff | Main Memory (256MB) |
| 0x9000_0000 - 0x90ff_ffff | IRQ Controller |
| 0x9100_0000 - 0x91ff_ffff | Timer |
| 0x9200_0000 - 0x92ff_ffff | UART |
| 0x9300_0000 - 0x93ff_ffff | SPI |
| 0x9400_0000 - 0x94ff_ffff | GPIO |

**Peripherals:**
- UART (1Mbaud default)
- Timer (2x 32-bit timers with interrupt)
- SPI (Master mode)
- GPIO (32-bit with interrupts)
- Interrupt controller (4 sources)

## Creating New Programs

1. Create a new demo directory:
   ```bash
   mkdir spud_rv32i-tools/demos/my_demo
   mkdir spud_rv32i-tools/demos/my_demo/src
   ```

2. Add your source code to `src/main.c`:
   ```c
   #include "spudkit.h"

   int main() {
       uart_init();
       uart_puts("Hello from my demo!\n");
       return 0;
   }
   ```

3. Build and run:
   ```bash
   ./build.sh my_demo
   ./run.sh my_demo
   ```

## Troubleshooting

**Toolchain not found:**
```bash
# Check installation
make -C spud_rv32i-tools check-toolchain

# Verify PATH
which riscv32-unknown-elf-gcc
```

**Serial port access denied:**
```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER
# Log out and back in for changes to take effect
```

**FPGA not responding:**
- Verify bitstream is loaded
- Check USB connections
- Try different serial device: `-d /dev/ttyUSB0`
- Reset FPGA board

**Simulation testbench not found:**
```bash
# Build testbench
cd spud_riscv_soc/tb
make
```

## Additional Resources

- [RISC-V SoC Documentation](spud_riscv_soc/README.md)
- [SpudKit Library Documentation](spud_rv32i-tools/README.md)
- [Testbench Guide](spud_riscv_soc/TESTBENCH_GUIDE.md)
- [Verilator Setup](spud_riscv_soc/VERILATOR_SETUP.md)
