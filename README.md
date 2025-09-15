# RISC-V (RV32I) Processor in VHDL

![VHDL](https://img.shields.io/badge/VHDL-2008-blue?style=for-the-badge&logo=vhdl)
![RISC-V](https://img.shields.io/badge/ISA-RISC--V%20RV32I-yellow?style=for-the-badge&logo=riscv)
![GHDL](https://img.shields.io/badge/Simulator-GHDL-green?style=for-the-badge&logo=ghdl)
![GTKWave](https://img.shields.io/badge/Waveform-GTKWave-9cf?style=for-the-badge&logo=gtkwave)


```

   ██████╗ ██╗   ██╗██████╗ ██████╗ ██╗
   ██╔══██╗██║   ██║╚════██╗╚════██╗██║
   ██████╔╝██║   ██║ █████╔╝ █████╔╝██║
   ██╔══██╗╚██╗ ██╔╝ ╚═══██╗██╔═══╝ ██║     ->> PROJETO: Processador RISC-V (RV32I) 
   ██║  ██║ ╚████╔╝ ██████╔╝███████╗██║     ->> AUTOR: André Solano F. R. Maiolini 
   ╚═╝  ╚═╝  ╚═══╝  ╚═════╝ ╚══════╝╚═╝     ->> DATA: 15/09/2025

```

This repository contains the implementation of a 32-bit, single-cycle processor that follows the base RISC-V instruction set specification (RV32I). The project is developed entirely in VHDL (2008 standard) and is intended as an educational project for studying computer architecture.

The design is modular, with each main processor component (ALU, Register File, Control Unit, etc.) implemented in its own file. Each module is accompanied by a self-verifying testbench to ensure correctness before final integration.

A top-level processor entity integrates all modules and can execute software compiled from C or Assembly, with the program being loaded dynamically into the simulation at runtime.

## 🎯 Goals and Features

* **Target ISA:** RISC-V RV32I (Base Integer Instruction Set).
* **Language:** VHDL-2008.
* **Focus:** Design clarity and educational purposes.
* **Verification:** Self-verifying testbenches for each component.
* **Automation:** Fully automated compilation and simulation flow via `Makefile`.

## 📂 Project Structure

The repository is organized as follows to separate the hardware design (RTL), simulation, and software.

```text
RV32I_processor/
├── rtl/                       # Synthesizable VHDL code (processor components)
│   ├── processor_top.vhd
│   ├── alu.vhd
│   └── ...
│
├── sim/                       # Testbenches and simulation support
│   ├── processor_top_tb.vhd
│   ├── memory_loader_pkg.vhd  # << VHDL package for dynamic program loading
│   └── ...
│
├── sw/                        # Example software programs
│   ├── src/
│   │   ├── hello.c
│   │   └── test_addi.s
│   ├── linker/
│   │   └── link.ld
│   └── start.s                # << Assembly boot code for C programs
│
├── build/                     # Auto-generated build output (ignored by Git)
│
├── Makefile                   # Automates compilation, simulation and visualization
│
└── .gitignore
```

## 🛠️ Prerequisites
To compile and simulate this project, install the following tools and ensure they are in your PATH:

1. GHDL: Open-source VHDL simulator.
2. GTKWave: Waveform viewer.
3. RISC-V GCC Toolchain (riscv32-unknown-elf-gcc): For compiling C/Assembly programs.

## 🚀 How to Compile and Simulate (Using the Makefile)

All commands are executed from the root of the repository. The Makefile automates software compilation, hardware simulation, and waveform visualization.

### 1. Clean Project
Removes all generated files:
```bash
make clean
```
This command will delete the `build/` directory, ensuring that no old files interfere with your simulation.

### 2. Compile Software

Compile a program written in C or Assembly located in sw/src/:
```bash
make sw SW=<program_name>
```
Example
```bash
make sw SW=test_addi
```

Generates build/sw/test_addi.hex that can be used as input for processor simulation.

### 3. Simulate Processor

Run the full processor simulation:

```bash
make sim TB=<testbench_name> [SW=<program_name>]
```

Examples:
```bash
# Run processor testbench only
make sim TB=processor_top_tb

# Run processor testbench with compiled software
make sim TB=processor_top_tb SW=test_addi
```

This produces a waveform file:
```bash
build/wave-processor_top_tb.ghw
```

### 4. Simulate Components

Run unit testbenches for processor components:
```bash
make comp TB=<component_tb>
```
Example:
```bash
make comp TB=alu_tb
```

### 5. Visualize Waveforms

Open the last simulation waveform in GTKWave:
```bash
make view TB=<testbench_name>
```
Example:
```bash
make view TB=alu_tb
```

## ✅ Verification
- Assertions inside testbenches provide PASS/FAIL messages directly in the terminal.
- For deeper inspection, use GTKWave to view signals and execution traces.

