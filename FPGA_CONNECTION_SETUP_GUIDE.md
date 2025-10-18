# FPGA Connection Setup Guide

This guide walks you through programming the Arty S7 FPGA for the SPUD project and running demos from WSL.

---

## 1. Program the FPGA using Vivado (Windows)

1. Open **Vivado** and navigate to the SPUD project:
spud_riscv_soc/fpga/arty/project.xpr


2. Perform the following steps:
   - **Synthesis** → run the synthesis process.
   - **Implementation** → run implementation after synthesis.
   - **Generate Bitstream** → generate the `.bit` file for programming the FPGA.

3. Open **Hardware Manager** in Vivado and connect to the FPGA.  
4. Program the FPGA with the generated bitstream.

> ⚠ Note: Do not attach the FPGA to WSL while Vivado Hardware Manager is connected. The USB/JTAG interface can only be used by one application at a time.

---

## 2. Attach FPGA USB to WSL (for UART / demo interaction)

### Step 2.1 — Bind device in PowerShell (Admin)
1. Open **PowerShell as Administrator**.
2. Bind the USB device to allow WSL to use it:
```powershell
usbipd bind --busid 3-3


Replace 3-3 with your board’s actual bus ID, which can be found via:

usbipd list

Step 2.2 — Attach device to WSL

Open regular PowerShell (does not need admin).

Attach the device to WSL:

usbipd attach --wsl --busid 3-3

Step 2.3 — Confirm in WSL

Open your WSL terminal.

Verify the FPGA USB appears:

ls /dev/ttyUSB*


Example output:

/dev/ttyUSB0  /dev/ttyUSB1

3. Build and Run Demos in WSL

Build a demo:

./build.sh [desired_demo]


Run a demo, specifying the correct USB device:

./run.sh [desired_demo] -d /dev/ttyUSB1


Make sure to use the USB device corresponding to the FPGA UART (usually /dev/ttyUSB1, but verify with ls /dev/ttyUSB*).

4. Notes / Tips

Always detach the USB device from WSL before programming the FPGA in Vivado again:

usbipd detach --busid 3-3


Only attach the USB to WSL after the FPGA is programmed.

Use screen or picocom in WSL for debugging UART if needed:

screen /dev/ttyUSB1 115200


Press reset on the FPGA after opening the serial terminal to see boot messages.
