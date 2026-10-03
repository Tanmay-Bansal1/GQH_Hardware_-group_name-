# GQH_Hardware_-group_name-

# [Team Name] - Silicon Trade Core

## Overview
This repository contains our submission for the Gator Quant Hacks Hardware Track. The system implements a 16-sample moving-average trading algorithm directly on the Tang Nano 20K FPGA. All UART parsing, state management, mathematical computation, and response generation happen on-chip.

## Hardware & Toolchain
* **Board**: Tang Nano 20K
* **HDL**: Verilog
* **Gowin EDA Version**: V1.9.11.03 Education
* **Device Configuration**: GW2AR-LV18QN88C8/I7

## Project Structure
* **Top-Level Module**: `top` (located in `src/top.v`)
* **Host-Side Tooling**: `21_quick_uart_test.py` and `22_robust_uart_test.py` used for local testing.

## Build & Programming Instructions
1. Open Gowin EDA and load the project from the `gowin/` directory.
2. Run **Synthesize**, followed by **Place & Route**.
3. Open the Programmer tool, scan for the GW2AR-18C device, and set the access mode to **SRAM Mode**.
4. Program the generated `bitstream/project.fs` file onto the board.

## Performance Results
* **Total LUT Count**: 271
* **Latency**: 16.752 ms
