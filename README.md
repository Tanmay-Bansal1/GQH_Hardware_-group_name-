# Silicon Trade Core

## Team Members

* Tanmay Bansal — bansalt@ufl.edu
* Jordan Serna — jordanserna@ufl.edu

## Project Overview

This project implements a highly optimized, hardware-accelerated 16-sample moving-average trading algorithm for the Gator Quant Hacks Hardware Track. It receives 8-byte price packets over a serial link, updates independent price windows for two items, computes mathematical crossings, and responds with BUY, SELL, or NONE actions. The architecture utilizes shiftless UART routing, single-bit item identification, and True Dual-Port BSRAM inference to aggressively minimize LUT usage.

## FPGA Implementation

During the official run, no team-supplied host software is executed. All UART parsing, state, algorithmic computation, and response generation happen on the FPGA.

Specific hardware implementations include:

* **UART RX/TX:** A zero-buffer, continuous-routing receiver that steers incoming bits directly into target registers, and a shiftless transmitter that indexes directly into the stable byte wire.
* **Packet Parser:** Big-endian multi-byte assembly and dynamic item ID echoing using combinational logic.


* **Moving Average Engine:** Independent 16-price circular buffers mapped to BSRAM, utilizing 20-bit rolling sums and bit-shift floor division to compute averages.


* **Crossing Logic:** Boolean-optimized crossing detection to evaluate BUY and SELL conditions without synthesizing wide 16-bit comparators.



## Host-Side Tooling (Local Testing Only)

* `21_quick_uart_test.py`: Quick sanity test for basic communication and packet format.


* `22_robust_uart_test_fullrange.py`: Scoring-style test with a software reference model.



## Hardware

* FPGA board: Tang Nano 20K.


* FPGA number / asset tag assigned to team: `#4`
* Additional hardware/peripherals used: None.

## HDL / Languages

* HDL used: Verilog.


* Host-side language(s) for local testing, if applicable: Python 3.



## Toolchain

* Gowin EDA version: V1.9.11.03 Education.


* Device part number: GW2AR-LV18QN88C8/I7.


* Other required software/tools: `pyserial` for Python testing.


## Top-Level Entity / Module

```text
top

```

## Top-Level Ports

```text
sys_clk    pin 4   in   27 MHz clock
reset_btn  pin 87  in   pull-down (optional)
uart_rx_i  pin 70  in   BL616 -> FPGA
uart_tx_o  pin 69  out  FPGA -> BL616
led0_n     pin 15  out  active low (optional)
led1_n     pin 16  out  active low (optional)

```

## Organizer-Supplied Constraint File

The organizer-provided `19_tang_nano_20k.cst` file is used and located in the `constraints/` directory of this repository. No custom constraint file was created, nor were the board pin constraints recreated in FloorPlanner.

## Repository Structure

* `src/`: Contains all HDL source files used by the FPGA design.


* `constraints/`: Contains the `19_tang_nano_20k.cst` file.


* `testbench/`: Contains testbench files.


* `gowin/`: Contains the Gowin project and build files.


* `bitstream/`: Contains the generated `.fs` programming file.


* `results/`: Contains the test CSVs and benchmarks.



## Build Instructions

1. Open/import the Gowin project.
2. Add/verify required source files.
3. Add the organizer-supplied `19_tang_nano_20k.cst` as the physical constraint file.


4. Verify the top-level entity/module.
5. Run synthesis.
6. Run Place & Route.
7. Locate the generated programming file (`impl/pnr/<project>.fs`) and copy it to the repository.


8. Note any project-specific steps: Ensure no simulation-only testbenches are added to the synthesis sources.



## Programming the Tang Nano 20K

Judges program in **SRAM mode**.

* `.fs` file location in this repository: `bitstream/project.fs`

## Fixed UART Interface

```text
PC -> FPGA:
[index16][item1_8][price1_16][item2_8][price2_16]

FPGA -> PC:
[index16][item1_8][action1_8][item2_8][action2_8][reserved16]

reserved = 0x0000

ITEM_A = 0x11
ITEM_B = 0x22

NONE = 0x00
SELL = 0x01
BUY  = 0x02

UART = 115200 baud, 8N1, LSB first
Packet size = 8 bytes each direction
Multi-byte fields = big-endian
Routing = by item ID; response mirrors request slot order

```

## How to Reproduce the Demo

1. Program the Tang Nano 20K with the `bitstream/project.fs` file using SRAM Mode.


2. Close the Gowin Programmer and any open serial terminals to free the COM port.


3. Execute `python 22_robust_uart_test_fullrange.py` from the command line.



Expected result:

```text
The script will transmit 100 packets[cite: 13, 14, 15]. The judge should observe a flawless run with 0 timeouts, 100% packet correctness, and 100% action correctness[cite: 13].

```

## Verification / Testing

The design was verified using the organizer-supplied `21_quick_uart_test.py` for protocol sanity and `22_robust_uart_test_fullrange.py` for full hardware evaluation. The `GAP_BITS` parameter in the UART transmitter was tuned experimentally via the robust test's CSV output to ensure the BL616 USB-serial bridge dropped zero bytes during back-to-back response transmission.

## Judging Metrics / Results

> Official judging uses one 100-packet run (indices 0–99): 84 scored packets and 168 scored actions.
> 
> 

### Correctness

* Local test used: `22_robust_uart_test_fullrange.py`

* Packet correctness (out of 84): 84
* Action correctness (out of 168): 168
* Estimated correctness points from `trade_summary_100_fullrange.txt` (out of 70): 70

### Latency

* Average measured round-trip latency: 16.804 ms
* Idle time or buffering between response bytes (BL616 workaround): 4 bit-times (`GAP_BITS = 4`) integrated directly into the UART transmitter state machine.
* Test/setup used: `22_robust_uart_test_fullrange.py`

### LUT Usage

After synthesis, open:

**Synthesis Report → Resource → Resource Usage Summary**

Record:

* **Total LUT (used for judging):** 119
* LUT2: 20
* LUT3: 38
* LUT4: 61
* Other relevant resource usage: ALU - 117


## Final Submission

* GitHub repository URL: https://github.com/Tanmay-Bansal1/GQH_Hardware_Stark-Silicon
* Devpost project URL: https://devpost.com/software/1462052

(Note: The full final Git commit SHA has been omitted from this README file, as a commit cannot contain its own SHA. The SHA is recorded directly on the Devpost submission page).