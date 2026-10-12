# Design and Functional Verification of a Simplified Out-of-Order Execution Engine

A SystemVerilog project implementing and functionally verifying a simplified out-of-order (OoO) execution engine using modular RTL design and testbenches.

## Overview

Out-of-order execution allows independent instructions to proceed without requiring every earlier instruction to finish first. Results still need to retire in program order to preserve architectural correctness.

This educational project demonstrates selected execution-engine concepts: instruction scheduling, register renaming, dependency handling, execution, result writeback, and in-order retirement.

## Architecture

| Module | Purpose |
|---|---|
| `ALU.sv` | Arithmetic and logical operations |
| `register_file.sv` | Architectural register storage |
| `rat.sv` | Register alias mapping for renaming |
| `reservation_station.sv` | Holds instructions while operands/resources are unavailable |
| `issue_unit.sv` | Controls instruction issue |
| `execution_unit.sv` | Executes issued operations |
| `reorder_buffer.sv` | Tracks in-flight instructions and supports ordered retirement |
| `ooo_core.sv` | Integrates the execution-engine components |

## Design Characteristics

- 32-bit datapath
- 32 architectural registers; R0 is treated as zero
- Two-read, one-synchronous-write register file
- Four-entry reservation station
- Eight-entry reorder buffer
- Three-bit ROB tags
- Fixed three-cycle execution latency
- Eight ALU operations
- Valid/ready handshaking
- In-order retirement through the reorder buffer

## Functional Verification

Dedicated SystemVerilog testbenches are included for the design modules and the integrated core. The `tb_ooo_core.sv` testbench contains seven integration scenarios:

1. Basic execution
2. Read-after-write (RAW) dependency
3. Independent instructions
4. ROB retirement order
5. Write-after-write (WAW) / register renaming
6. Multiple in-flight instructions
7. ROB wraparound and input backpressure

The saved ModelSim transcript reports PASS messages for the checks shown in each of these seven sections. The transcript and waveform screenshots are supporting evidence; they are not a substitute for independently rerunning the tests.

## Project Structure

```text
OoO-Execution-Engine/
├── rtl/                    # Eight RTL modules
├── tb/                     # Eight SystemVerilog testbenches
├── results/                # Integration transcript and core waveform
├── Waveforms Images/       # Module and integration waveform screenshots
└── README.md
```

## Tools

- SystemVerilog
- ModelSim-Altera 10.0c / Quartus II 11.1 Starter Edition

## Running the Simulation

1. Open ModelSim and create or open a project.
2. Add the RTL source files from `rtl/`.
3. Add the testbench files from `tb/`.
4. Compile the RTL modules and the chosen testbench. Compile dependencies before modules that instantiate them.
5. Start the chosen testbench (for integration, `tb_ooo_core`) and run the simulation to completion.
6. Inspect the transcript for test results and open the waveform for signal-level debugging.

The exact commands and compile order may depend on the ModelSim project setup.

## Scope and Limitations

This is a simplified educational execution engine, not a complete processor. It does not implement instruction fetch/decode, a complete ISA, a memory hierarchy or cache, branch prediction, or speculative branch recovery.

## Author

Jay Vyas  
Electronics and Communication Engineering | Digital Design | SystemVerilog | Functional Verification
