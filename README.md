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

This repository contains the implementation of a 32-bit RISC-V processor (RV32I ISA) with support for multiple microarchitectures. The project is developed entirely in VHDL (2008 standard) and is intended as an educational project for studying computer architecture and processor design.

The design is modular, with each main processor component (ALU, Register File, Control Unit, etc.) implemented in its own file. Each module is accompanied by a self-verifying testbench to ensure correctness before final integration. The architecture is extensible, allowing easy addition of new microarchitectures (single-cycle, multi-cycle, pipelined, etc.) without modifying the core ISA definitions.

A top-level processor entity integrates all modules and can execute software compiled from C or Assembly, with the program being loaded dynamically into the simulation at runtime. The project includes a System-on-Chip (SoC) integration layer with bootloader support and configurable memory mapping.

## 🎯 Goals and Features

* **Target ISA:** RISC-V RV32I (Base Integer Instruction Set).
* **Microarchitectures:** Single-cycle, multi-cycle [on going].
* **Language:** VHDL-2008.
* **Focus:** Design clarity, modularity, and educational purposes.
* **Verification:** Self-verifying testbenches for each component using COCOTB (Python).
* **Automation:** Fully automated build system via `Makefile` with dynamic CORE selection, automatic software compilation, and linker script selection.

## 📂 Project Structure

The repository is organized as follows to separate the hardware design (RTL), simulation, and software.

```text
RISC-V/
|
├── rtl/                              # Synthesizable VHDL code (processor RTL)
│   ├── core/                         # Core processor components
│   │   ├── common/                   # ISA-common components (used by all microarchitectures)
│   │   │   ├── alu.vhd               # Arithmetic Logic Unit
│   │   │   ├── [...]
│   │   │   └── store_unit.vhd        # Store operation unit
│   │   ├── single_cycle/             # Single-cycle microarchitecture
│   │   │   ├── [...]
│   │   │   ├── datapath.vhd          # Datapath
│   │   │   └── processor_top.vhd     # Top-level processor
│   │   └── multi_cycle/              # Multi-cycle microarchitecture [on going]
│   │
│   ├── soc/                          # System-on-Chip integration
│   │   ├── boot_rom.vhd              # Boot ROM with bootloader
│   │   ├── bus_interconnect.vhd      # Bus interconnect
│   │   ├── dual_port_ram.vhd         # Dual-port RAM
│   │   └── soc_top.vhd               # Top-level SoC
│   │
│   └── perips/                       # Peripherals
│       └── uart/                     # UART controller (future)
│
├── sim/                              # Testbenches (Python + cocotb)
│   ├── core/                         # Component testbenches
│   │   ├── common/                   # Tests for common components
│   │   │   ├── test_alu.py
│   │   │   ├── test_imm_gen.py
│   │   │   ├── test_load_unit.py
│   │   │   ├── [...]
│   │   │   └── test_store_unit.py
│   │   ├── single_cycle/             # Tests for single-cycle implementation
│   │   │   ├── test_control.py
|   |   |   ├── test_processor.py
│   │   │   ├── test_datapath.py
│   │   │   ├── test_decoder.py
│   │   │   └── wrappers/             # VHDL wrappers for testbenches
│   │   └── multi_cycle/              # Tests for multi-cycle [on going]
│   │
│   ├── soc/                          # SoC testbenches
│   │   ├── test_boot_rom.py
│   │   ├── [...]
│   │   ├── test_memory_system.py
│   │   └── wrappers/                 # VHDL wrappers for testbenches
│   │
│   ├── perips/                       # Peripheral testbenches
│   │   ├── test_uart_controller.py
│   │   ├── test_uart_rx.py
│   │   └── test_uart_tx.py
│   │
│   └── common/                       # Shared test utilities
│       └── test_utils.py
│
├── pkg/                              # VHDL packages
│   └── riscv_isa_pkg.vhd             # RISC-V ISA definitions (ISA-agnostic)
│
├── sw/                               # Software programs (C and Assembly)
│   ├── apps/                         # User applications
│   │   ├── hello.c
│   │   ├── fibonacci.c
│   │   ├── console_test.c
│   │   ├── branch_test.s
│   │   └── test_all.s
│   └── platform/
│       ├── bootloader/
│       │   └── boot.c
│       ├── startup/
│       │   ├── crt0.s                # C Runtime Zero
│       │   └── start.s               # Boot Start
│       └── linker/
│           ├── link.ld               # Processor linker script (ORIGIN=0x00000000)
│           ├── link_soc.ld           # SoC linker script (ORIGIN=0x80000000)
│           └── boot.ld               # Bootloader linker script
│
├── docs/                             # Documentation (LaTeX ABNT thesis)
├── fpga/                             # FPGA configuration (future)
├── build/                            # Auto-generated build output (ignored by Git)
|   ├── boot/
│   ├── cocotb/
│   │   ├── single_cycle/             # Output for single_cycle architecture
│   │   └── multi_cycle/              # Output for multi_cycle architecture
│   └── sw/                           # Compiled software
│
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

All commands are executed from the root of the repository. The Makefile automates software compilation, hardware simulation via COCOTB, and waveform visualization. It supports dynamic architecture selection (CORE), automatic software compilation, and linker script selection based on the test type.

```
 
     ██████╗ ██╗███████╗ ██████╗ ██╗   ██╗    
     ██╔══██╗██║██╔════╝██╔════╝ ██║   ██║    
     ██████╔╝██║███████╗██║█████╗██║   ██║    
     ██╔══██╗██║╚════██║██║╚════╝╚██╗ ██╔╝    
     ██║  ██║██║███████║╚██████╗  ╚████╔╝     
     ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝   ╚═══╝      
 
=========================================================================================================
                        RISC-V Project Build System                      
=========================================================================================================
 
 📦 SOFTWARE COMPILATION
 ────────────────────────────────────────────────────────────────────────────────────────────────────────
   make sw SW=<prog>                                            Compilar aplicação C/ASM (em sw/apps)
   make boot                                                    Compilar bootloader (em sw/bootloader)
   make list-apps                                               Listar aplicações disponíveis
 
 🧪 HARDWARE TESTING & SIMULATION
 ────────────────────────────────────────────────────────────────────────────────────────────────────────
   make cocotb [CORE=<core>] TEST=<test> TOP=<top> [SW=<prog>]  Rodar teste COCOTB
   make cocotb TEST=<test> TOP=<top>                            Teste de componente (unit)
   make list-tests [CORE=<core>]                                Listar testes disponíveis
 
 📊 VISUALIZATION & DEBUG
 ────────────────────────────────────────────────────────────────────────────────────────────────────────
   make view TEST=<test>                                        Abrir ondas (VCD) no GTKWave
 
 🧹 MAINTENANCE
 ────────────────────────────────────────────────────────────────────────────────────────────────────────
   make clean                                                   Limpar diretório de build
 
=========================================================================================================

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

Generates `build/sw/hello.hex` and `build/sw/hello.bin` that can be used as input for processor simulation.

**Note:** When running COCOTB tests with `SW=<prog>`, the software is compiled automatically, so explicit `make sw` is optional.

### 3. Run Automated Tests with COCOTB

Run automated tests using COCOTB (Python-based coroutine testbenches):

```bash
make cocotb [CORE=<core>] TEST=<testbench_name> TOP=<top_level> [SW=<program_name>]
```

**Parameters:**
- `CORE`: Microarchitecture to test (default: `single_cycle`). Options: `single_cycle`, `multi_cycle`, or any custom architecture
- `TEST`: Name of the Python testbench file (without `.py` extension) located in `sim/core/<core>/`, `sim/core/common/`, `sim/soc/`, or `sim/perips/`
- `TOP`: Top-level VHDL entity to test (default: `processor_top`)
- `SW`: Optional software program to load into memory during simulation. **Automatically compiled if not present.**

**Examples:**

```bash
# Unit tests - Common components (work with all architectures)
make cocotb TEST=test_alu TOP=alu
make cocotb TEST=test_reg_file TOP=reg_file
make cocotb TEST=test_imm_gen TOP=imm_gen
make cocotb TEST=test_load_unit TOP=load_unit
make cocotb TEST=test_store_unit TOP=store_unit

# Single-cycle specific tests (default architecture)
make cocotb TEST=test_alu_control TOP=alu_control
make cocotb TEST=test_control TOP=control
make cocotb TEST=test_datapath TOP=datapath_wrapper
make cocotb TEST=test_decoder TOP=decoder_wrapper

# Processor test with software (automatic compilation & memory mapping)
make cocotb TEST=test_processor TOP=processor_top SW=hello
make cocotb TEST=test_processor TOP=processor_top SW=fibonacci

# Multi-cycle architecture (when available)
make cocotb CORE=multi_cycle TEST=test_datapath TOP=datapath_wrapper

# SoC tests with automatic bootloader compilation
make cocotb TEST=test_soc_top TOP=soc_top
make cocotb TEST=test_boot_rom TOP=boot_rom

```

**What happens:**
- The Makefile automatically detects the architecture (CORE) and selects appropriate linker script
- The software is automatically compiled if `SW=` is specified
- The bootloader is automatically compiled for SoC tests (`boot_rom`, `soc_top`, etc.)
- GHDL simulator runs under COCOTB control
- Python testbenches interact with VHDL signals in real-time
- Test results are logged to the terminal
- Waveforms are generated in VCD format for inspection

**Memory Mapping:**
- **Processor tests** (processor_top): `0x00000000` (using `link.ld`)
- **SoC tests** (soc_top, boot_rom, etc.): `0x80000000` (using `link_soc.ld`)

**Output:**
- Terminal: Test pass/fail messages with detailed logging
- `build/cocotb/<core>/results.xml`: Test results in XML format
- `build/cocotb/<core>/wave-test_<name>.vcd`: Waveform file for visualization

### 4. Visualize Waveforms

Open the last simulation waveform in GTKWave:
```bash
make view [CORE=<core>] TEST=<testbench_name>
```

Example:
```bash
make view TEST=test_processor
make view CORE=single_cycle TEST=test_datapath
```

This opens `build/cocotb/<core>/wave-test_<testbench_name>.vcd` in GTKWave for detailed signal inspection.

## ✅ Verification

This project uses **COCOTB** (Coroutine-based Co-simulation Testbench) for comprehensive automated testing:

- **Python Testbenches**: Testbenches are written in Python using COCOTB, making them more readable and maintainable than traditional VHDL testbenches.
- **Self-Verifying Tests**: Each module includes automated assertions that validate correct behavior.
- **Real-Time Signal Access**: Python can directly interact with VHDL signals for precise control and monitoring.
- **Detailed Logging**: Tests provide detailed console output showing all test cases and results.
- **Waveform Generation**: Each test generates VCD waveforms for deeper inspection using GTKWave.
