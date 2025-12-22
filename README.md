# RISC-V (RV32I) Processor in VHDL

![VHDL](https://img.shields.io/badge/VHDL-2008-blue?style=for-the-badge&logo=vhdl)
![RISC-V](https://img.shields.io/badge/ISA-RISC--V%20RV32I-yellow?style=for-the-badge&logo=riscv)
![GHDL](https://img.shields.io/badge/Simulator-GHDL-green?style=for-the-badge&logo=ghdl)
![GTKWave](https://img.shields.io/badge/Waveform-GTKWave-9cf?style=for-the-badge&logo=gtkwave)
![Python](https://img.shields.io/badge/Python-3.10-blue?style=for-the-badge&logo=python)


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
RISC-V/
|
├── rtl/                              # Synthesizable VHDL code (processor RTL)
│   ├── core/                         # Core processor components
│   │   ├── alu.vhd                   # Arithmetic Logic Unit
│   │   ├── [...]
│   │   └── store_unit.vhd            # Store operation unit
│   ├── soc/                          # System-on-Chip components
│   └── perips/                       # Peripherals (future)
│
├── sim/                              # Testbenches (Python + cocotb)
│   ├── core/                         # Component testbenches
│   │   ├── decoder_wrapper.vhd       # Wrapper for decoder testing
│   │   ├── test_alu.py               # ALU testbench
│   │   ├── [...]
│   │   └── test_store_unit.py        # Store unit testbench
│   ├── soc/                          # SoC testbenches
│   └── common/                       # Shared test utilities and constants
│
├── pkg/                              # VHDL packages
│   ├── riscv_pkg.vhd                 # RISC-V constants and types
│   └── memory_loader_pkg.vhd         # Dynamic program loading package
│
├── sw/                               # Software programs (C and Assembly)
│   ├── start.s                       # Assembly boot code for C programs
│   ├── apps/                         # User applications
│   │   ├── hello.c                   # Hello world example
│   │   └── [...] 
│   └── common/
│       └── link.ld                   # Linker script
│
├── docs/                             # Documentation (LaTeX ABNT thesis)
|
├── fpga/                             # FPGA configuration (future)
│   └── README.md
│
├── build/                            # Auto-generated build output (ignored by Git)
|
├── makefile                          # Build automation (compilation, simulation, visualization)
├── README.md                         # This file
└── .gitignore                        # Git ignore rules
```

## 🛠️ Prerequisites
To compile and simulate this project, install the following tools and ensure they are in your PATH:

1. GHDL: Open-source VHDL simulator.
2. GTKWave: Waveform viewer.
3. RISC-V GCC Toolchain (riscv32-unknown-elf-gcc): For compiling C/Assembly programs.
4. COCOTB: Python-based coroutine testbench framework for hardware simulation.
5. Python 3: Required for running cocotb testbenches.

## 🚀 How to Compile and Simulate (Using the Makefile)

All commands are executed from the root of the repository. The Makefile automates software compilation, hardware simulation via COCOtb, and waveform visualization.

```
 
     ██████╗ ██╗███████╗ ██████╗ ██╗   ██╗    
     ██╔══██╗██║██╔════╝██╔════╝ ██║   ██║    
     ██████╔╝██║███████╗██║█████╗██║   ██║    
     ██╔══██╗██║╚════██║██║╚════╝╚██╗ ██╔╝    
     ██║  ██║██║███████║╚██████╗  ╚████╔╝     
     ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝   ╚═══╝      
 
 
===========================================================================================
           Ambiente de Projeto RISC-V   
===========================================================================================
 
 make sw SW=<prog>                           -> Compilar app de usuário (em sw/apps)   
 make boot                                   -> Compilar bootloader (em sw/bootloader) 
 make cocotb TEST=<tb> TOP=<top> [SW=<prog>] -> Rodar testes automatizados com COCOTB  
 make view TB=<tb>                           -> Abrir ondas para debubg no GTKWave     
 make clean                                  -> Limpar diretório build                 
 
===========================================================================================
```

### 1. Clean Project
Removes all generated files:
```bash
make clean
```

### 2. Compile Software

Compile a program written in C or Assembly located in `sw/apps/`:
```bash
make sw SW=<program_name>
```

Example:
```bash
make sw SW=hello
```

Generates `build/sw/hello.hex` that can be used as input for processor simulation.

### 3. Run Automated Tests with COCOTB

Run automated tests using COCOTB (Python-based coroutine testbenches):

```bash
make cocotb TEST=<testbench_name> TOP=<top_level> [SW=<program_name>]
```

**Parameters:**
- `TEST`: Name of the Python testbench file (without `.py` extension) located in `sim/core/` or `sim/soc/`
- `TOP`: Top-level VHDL entity to test (default: `processor_top`)
- `SW`: Optional software program to load into memory during simulation

**Examples:**

```bash
# Test individual components (ALU, Decoder, Register File, etc.)
make cocotb TEST=test_alu TOP=alu
make cocotb TEST=test_alu_control TOP=alu_control
make cocotb TEST=test_reg_file TOP=reg_file
make cocotb TEST=test_branch_unit TOP=branch_unit
make cocotb TEST=test_decoder TOP=decoder
make cocotb TEST=test_imm_gen TOP=imm_gen
make cocotb TEST=test_load_unit TOP=load_unit
make cocotb TEST=test_store_unit TOP=store_unit
[...]

# Test processor with software program
make cocotb TEST=test_processor TOP=processor_top SW=hello
[...]

```

**What happens:**
- The Makefile automatically compiles the software (if `SW=` is specified)
- GHDL simulator runs under COCOTB control
- Python testbenches interact with VHDL signals in real-time
- Test results are logged to the terminal
- Waveforms are generated in VCD format for inspection

**Output:**
- Terminal: Test pass/fail messages with detailed logging
- `build/cocotb/results.xml`: Test results in XML format
- `build/cocotb/wave-test_<name>.ghw`: Waveform file for visualization

### 4. Visualize Waveforms

Open the last simulation waveform in GTKWave:
```bash
make view TEST=<testbench_name>
```

Example:
```bash
make view TEST=test_processor
```

This opens `build/cocotb/wave-test_processor.vcd` in GTKWave for detailed signal inspection.

## ✅ Verification

This project uses **COCOTB** (Coroutine-based Co-simulation Testbench) for comprehensive automated testing:

- **Python Testbenches**: Testbenches are written in Python using COCOTB, making them more readable and maintainable than traditional VHDL testbenches.
- **Self-Verifying Tests**: Each module includes automated assertions that validate correct behavior.
- **Real-Time Signal Access**: Python can directly interact with VHDL signals for precise control and monitoring.
- **Detailed Logging**: Tests provide detailed console output showing all test cases and results.
- **Waveform Generation**: Each test generates VCD waveforms for deeper inspection using GTKWave.

### Test Organization

```
sim/
├── core/
│   ├── test_alu.py              # Tests for Arithmetic Logic Unit
│   ├── [...]
│   └── decoder_wrapper.vhd      # Wrapper for decoder testing
├── soc/
|   ├── [...]
│   └── test_dual_port_ram.py    # Tests for Memory Module
└── common/
    ├── [...]
    └── test_utils.py            # Shared utilities and constants
```
