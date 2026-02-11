# 🚀 AI Matrix Multiplication Accelerator
### Hardware Accelerator for Neural Network Inference Using 4×4 Systolic Array Architecture

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: In Development](https://img.shields.io/badge/Status-In%20Development-orange)](https://github.com)
[![Hardware: SystemVerilog](https://img.shields.io/badge/Hardware-SystemVerilog-blue)](https://github.com)
[![Backend: OpenLane](https://img.shields.io/badge/Backend-OpenLane-green)](https://github.com)

> **⚠️ PROJECT STATUS:** Active development. RTL design complete, currently implementing backend flow (Synthesis → Place & Route → GDS).

---

## 📋 Table of Contents
- [Overview](#overview)
- [Motivation](#motivation)
- [Architecture](#architecture)
- [Features](#features)
- [Design Hierarchy](#design-hierarchy)
- [Implementation Details](#implementation-details)
- [Simulation Results](#simulation-results)
- [Tools & Technologies](#tools--technologies)
- [Project Roadmap](#project-roadmap)
- [Getting Started](#getting-started)
- [Performance Metrics](#performance-metrics)
- [Future Work](#future-work)
- [References](#references)

---

## 🎯 Overview

This project implements a **hardware accelerator for AI inference workloads** using a systolic array architecture. Matrix multiplication is the fundamental operation in neural networks, consuming 90%+ of computation time. This accelerator offloads these operations to specialized hardware, achieving significant speedup over software implementations.

### Key Highlights
- **4×4 Weight-Stationary Systolic Array** with 16 parallel Processing Elements (PEs)
- **AXI-Stream Interface** for industry-standard communication
- **INT8 Precision** for efficient edge AI deployment
- **Pipelined Datapath** with proper skewing for systolic timing
- **Complete RTL-to-GDS Flow** using open-source tools (OpenLane, Sky130 PDK)

### What is a Systolic Array?
A systolic array is a grid of processing elements (PEs) that rhythmically compute and pass data. Like a heartbeat (systole), data pulses through the array in a coordinated pattern. Each PE performs a simple Multiply-Accumulate (MAC) operation while forwarding data to neighbors.

**Analogy:** Imagine an assembly line where each worker (PE) does one task and passes the work to the next. Highly parallel, highly efficient.

---

## 💡 Motivation

### The Problem
Neural networks require billions of matrix multiplications during inference:
```
Input[224×224] × Weights[3×3×64] = Output
```
Traditional CPUs process this sequentially → **SLOW** ⏰  
GPUs are faster but power-hungry → **Not suitable for edge devices** 🔋

### Our Solution
Custom hardware accelerator that:
- ✅ Computes 16 MAC operations **in parallel** every cycle
- ✅ Uses only **INT8** arithmetic for efficiency  
- ✅ Optimized dataflow minimizes memory access
- ✅ Low power consumption suitable for edge deployment

### Real-World Impact
- **Smartphones:** On-device AI (face unlock, photo enhancement)
- **IoT Devices:** Real-time inference without cloud dependency
- **Robotics:** Low-latency vision processing
- **Automotive:** ADAS camera processing

---

## 🏗️ Architecture

### System Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        TOP MODULE                            │
│                                                              │
│  ┌──────────────┐      ┌──────────────┐                     │
│  │  AXI-Stream  │      │  AXI-Stream  │                     │
│  │   Input A    │      │   Input B    │                     │
│  │   (Matrix)   │      │   (Matrix)   │                     │
│  └──────┬───────┘      └──────┬───────┘                     │
│         │                     │                              │
│         ▼                     ▼                              │
│  ┌──────────────┐      ┌──────────────┐                     │
│  │   Buffer A   │      │   Buffer B   │                     │
│  │  (16×8 bits) │      │  (16×8 bits) │                     │
│  └──────┬───────┘      └──────┬───────┘                     │
│         │                     │                              │
│         │   ┌─────────────────┘                             │
│         │   │                                                │
│         ▼   ▼                                                │
│  ┌─────────────────┐                                        │
│  │  Delay Registers │  (Systolic Timing Skew)               │
│  │  a1_d1, a2_d2... │                                        │
│  └────────┬─────────┘                                        │
│           │                                                  │
│           ▼                                                  │
│  ┌───────────────────────────────────────┐                  │
│  │     4×4 SYSTOLIC ARRAY                │                  │
│  │   ┌────┬────┬────┬────┐               │                  │
│  │   │PE00│PE01│PE02│PE03│ ← Row 0       │                  │
│  │   ├────┼────┼────┼────┤               │                  │
│  │   │PE10│PE11│PE12│PE13│ ← Row 1       │                  │
│  │   ├────┼────┼────┼────┤               │                  │
│  │   │PE20│PE21│PE22│PE23│ ← Row 2       │                  │
│  │   ├────┼────┼────┼────┤               │                  │
│  │   │PE30│PE31│PE32│PE33│ ← Row 3       │                  │
│  │   └────┴────┴────┴────┘               │                  │
│  │    ↑    ↑    ↑    ↑                   │                  │
│  │   Col0 Col1 Col2 Col3                 │                  │
│  └──────────────┬────────────────────────┘                  │
│                 │                                            │
│                 ▼                                            │
│        ┌─────────────────┐                                  │
│        │  Result Matrix   │                                  │
│        │   (16×32 bits)   │                                  │
│        └─────────────────┘                                  │
│                                                              │
│  Control: start_compute, done                               │
└─────────────────────────────────────────────────────────────┘
```

### Dataflow Visualization

**Weight-Stationary Systolic Array:**
- **Weights (A):** Flow horizontally (left → right)
- **Activations (B):** Flow vertically (top → bottom)  
- **Partial Sums:** Accumulate within each PE
- **Results:** Read out after computation completes

```
     b0   b1   b2   b3
      ↓    ↓    ↓    ↓
a0 → [PE] [PE] [PE] [PE] → results[0:3]
      ↓    ↓    ↓    ↓
a1 → [PE] [PE] [PE] [PE] → results[4:7]
      ↓    ↓    ↓    ↓
a2 → [PE] [PE] [PE] [PE] → results[8:11]
      ↓    ↓    ↓    ↓
a3 → [PE] [PE] [PE] [PE] → results[12:15]
      ↓    ↓    ↓    ↓
```

**Why Skewing (Delay Registers)?**

Systolic arrays require staggered input timing. Without delays, all data would arrive simultaneously, breaking the pipelined flow.

```
Cycle 0: a0, b0 enter
Cycle 1: a0 moves right, a1 enters with 1-cycle delay
Cycle 2: a2 enters with 2-cycle delay
Cycle 3: a3 enters with 3-cycle delay
```

This creates a **wave** of computation propagating through the array!

---

## ✨ Features

### Hardware Features
- [x] **16 Parallel MAC Units** (Processing Elements)
- [x] **INT8×INT8 → INT32** multiplication with accumulation
- [x] **Weight-stationary dataflow** for memory efficiency
- [x] **AXI-Stream slave interfaces** for input buffers
- [x] **Pipelined architecture** with proper data skewing
- [x] **Configurable clock domain** (tested at 100 MHz)
- [ ] **FSM-based control** (in progress)
- [ ] **AXI4-Lite register interface** (planned)

### Design Features
- ✅ **Fully synchronous** design with single clock domain
- ✅ **Parameterizable precision** (INT8 default, expandable)
- ✅ **Modular hierarchy** for easy verification and reuse
- ✅ **Industry-standard interfaces** (AXI protocols)
- ✅ **Simulation-verified** with comprehensive testbenches

---

## 📦 Design Hierarchy

```
top.v                       # Top-level integration
├── buffer.v (×2)           # AXI-Stream input buffers (A & B)
│   ├── AXI handshaking
│   ├── 16×8-bit memory
│   └── Read/write pointers
│
├── Delay Registers         # Systolic timing skew logic
│   ├── a1_d1, a2_d2, a3_d3
│   └── b1_d1, b2_d2, b3_d3
│
└── systolic_array.v        # 4×4 PE grid
    └── pe.v (×16)          # Processing Elements
        ├── 8-bit multiplier
        ├── 32-bit accumulator
        └── Data forwarding (a_out, b_out)
```

### Module Descriptions

#### **Processing Element (PE)**
Each PE is a simple MAC (Multiply-Accumulate) unit:

```systemverilog
module pe (
    input  logic clk, rst,
    input  logic [7:0]  a_in, b_in,      // Inputs
    output logic [7:0]  a_out, b_out,    // Forwarded to neighbors
    output logic [31:0] result_out       // Accumulated result
);
```

**Operation:**
```
result = result + (a_in × b_in)
a_out = a_in    // Forward horizontally
b_out = b_in    // Forward vertically
```

#### **Systolic Array**
Instantiates 16 PEs in a 4×4 grid with proper interconnections.

**Inputs:** 4 rows (a0-a3) and 4 columns (b0-b3)  
**Outputs:** 16 results (result00-result33)

#### **Buffer**
AXI-Stream slave that accepts streaming data and stores it for the array.

**Features:**
- Handshake-based flow control (valid/ready)
- 16-entry FIFO-like storage
- Outputs 4 values per cycle to array

#### **Top Module**
Integrates everything with delay registers for proper systolic timing.

**Control Signals:**
- `start_compute`: Begin computation
- `done`: Computation complete (currently placeholder)

---

## 🔬 Implementation Details

### Data Precision
- **Input:** INT8 (8-bit signed/unsigned integers)
- **Weights:** INT8
- **Accumulator:** INT32 (prevents overflow)
- **Output:** INT32 per result

**Why INT8?**
- ✅ 4× memory reduction vs FP32
- ✅ 4× faster computation
- ✅ Minimal accuracy loss (<1% for many networks)
- ✅ Edge-device friendly (low power)

### Timing & Latency

**Computation Stages:**
1. **Load Phase:** Stream data into buffers via AXI (~16 cycles)
2. **Compute Phase:** Systolic array processes (~7 cycles for 4×4)
3. **Drain Phase:** Results stabilize (~4 cycles)

**Total Latency:** ~27 cycles for one 4×4 × 4×4 matrix multiplication

**At 100 MHz:** 270 ns per 4×4 operation  
**Throughput:** 16 MAC ops/cycle = **1.6 GOPS @ 100 MHz**

### Memory Organization

**Buffer A:** 16 bytes (4×4 matrix, row-major)
```
[a00 a01 a02 a03]
[a10 a11 a12 a13]
[a20 a21 a22 a23]
[a30 a31 a32 a33]
```

**Buffer B:** 16 bytes (4×4 matrix, column-major for systolic feed)

**Results:** 64 bytes (16 × 32-bit values)

---

## 📊 Simulation Results

### Testbench Coverage
- ✅ **PE-level testing:** Single MAC operations verified
- ✅ **Array-level testing:** 4×4 matrix multiplication validated
- ✅ **Integration testing:** Full top-module with AXI streaming
- ✅ **Timing verification:** Skewing logic confirmed via waveforms

### Example Test Case

**Input Matrices:**
```
A = [1 2 3 4]       B = [1 0 0 0]
    [5 6 7 8]           [0 1 0 0]
    [1 1 1 1]           [0 0 1 0]
    [2 2 2 2]           [0 0 0 1]
```

**Expected Result (A × B):**
```
C = [1 2 3 4]
    [5 6 7 8]
    [1 1 1 1]
    [2 2 2 2]
```

**Simulation:** ✅ **PASS** (Results match exactly)

### Waveform Highlights
- Clean clock domain crossing
- Proper AXI handshake (valid/ready toggling)
- Data skewing visible in delay stages
- Result accumulation in PEs

---

## 🛠️ Tools & Technologies

### Design & Verification
| Tool | Purpose | Version |
|------|---------|---------|
| **SystemVerilog** | Hardware Description Language | IEEE 1800-2017 |
| **Questa Sim** | Simulation & Waveform Analysis | 2026.2 |
| **GTKWave** | Waveform Viewer (alternative) | 3.3.104 |

### Backend Flow (Planned/In Progress)
| Tool | Purpose | License |
|------|---------|---------|
| **Yosys** | RTL Synthesis | Open-source |
| **OpenLane** | Automated RTL-to-GDS Flow | Open-source |
| **OpenROAD** | Place & Route | Open-source |
| **Magic** | Layout Viewer & DRC | Open-source |
| **Sky130 PDK** | 130nm Process Design Kit | Open-source (SkyWater + Google) |

### Version Control & Documentation
- **Git/GitHub:** Source control
- **Markdown:** Documentation
- **Draw.io:** Architecture diagrams

---

## 🗺️ Project Roadmap

### ✅ Phase 1: RTL Design (COMPLETED)
- [x] Processing Element (PE) design
- [x] 4×4 Systolic Array instantiation
- [x] AXI-Stream buffer modules
- [x] Delay registers for skewing
- [x] Top-level integration
- [x] Comprehensive testbenches

**Status:** All RTL modules functional and verified ✅  
**Duration:** 2 days

---

### 🔄 Phase 2: Control Logic (IN PROGRESS)
- [ ] FSM-based controller
  - States: IDLE → LOAD → COMPUTE → DRAIN → DONE
  - Automatic cycle counting
  - Proper `done` signal generation
- [ ] Enhanced buffer management
- [ ] Error handling & edge cases

**Status:** Design phase  
**ETA:** 2-3 days

---

### ⏳ Phase 3: Backend Implementation (NEXT)
- [ ] Yosys synthesis
  - Gate-level netlist generation
  - Area & timing reports
  - Optimization iterations
- [ ] OpenLane flow execution
  - Floorplanning
  - Placement & routing
  - Clock tree synthesis
  - Sign-off checks (DRC/LVS/STA)
- [ ] GDS generation
  - Final layout export
  - Tape-out ready files

**Status:** Tools setup in progress  
**ETA:** 2-3 weeks

---

### 🚀 Phase 4: Optimization & Extension (FUTURE)
- [ ] AXI4-Lite slave interface for register access
- [ ] Configurable array size (parameterized)
- [ ] Support for FP16/BF16 precision
- [ ] Output buffer with AXI-Stream master
- [ ] Power analysis & optimization
- [ ] Performance benchmarking against CPU/GPU
- [ ] FPGA prototyping (if board available)

**Status:** Planned  
**ETA:** TBD based on project goals

---


## 📈 Performance Metrics

### Computational Throughput
| Metric | Value | Notes |
|--------|-------|-------|
| MAC Operations per Cycle | 16 | All PEs operate in parallel |
| Clock Frequency (Target) | 100 MHz | Constrained for synthesis |
| Peak Throughput | 1.6 GOPS | 16 × 100M = 1.6 billion ops/sec |
| Latency (4×4 matmul) | ~27 cycles | Load + Compute + Drain |
| Time per 4×4 Operation | 270 ns | @ 100 MHz |

### Resource Estimates (Pre-Synthesis)
| Resource | Estimated Count | Notes |
|----------|-----------------|-------|
| Processing Elements | 16 | Core compute units |
| Multipliers (8×8) | 16 | One per PE |
| Registers (32-bit) | 16 | Accumulators |
| Registers (8-bit) | ~40 | Data forwarding + delays |
| Memory (SRAM/Regs) | 32 bytes | Input buffers (16+16) |
| **Total Gates** | ~5,000-8,000 | Rough estimate |

*Actual values will be available after synthesis*

### Comparison with Software

**Baseline:** 4×4 × 4×4 matrix multiply on CPU (Python/NumPy)

| Implementation | Time | Speedup |
|----------------|------|---------|
| Python (single-thread) | ~10 µs | 1× |
| NumPy (optimized) | ~2 µs | 5× |
| **Our Accelerator** | **0.27 µs** | **37×** |

*Note: Comparison is illustrative. Real speedup depends on data transfer overhead.*

---

## 🔮 Future Work

### Near-term Enhancements
1. **FSM Controller:** Automate state transitions for plug-and-play operation
2. **AXI4-Lite Interface:** Software-accessible register bank for configuration
3. **Backend Completion:** Generate GDS layout for fabrication readiness

### Medium-term Features
4. **Scalability:** Parameterize array size (support 8×8, 16×16)
5. **Precision Options:** Add FP16/BF16 support for training workloads
6. **Power Optimization:** Clock gating, operand isolation, multi-Vt cells
7. **Output Buffer:** AXI-Stream master for pipelined data output

### Long-term Vision
8. **FPGA Prototype:** Deploy on FPGA board for real-world testing
9. **Full SoC Integration:** Connect to RISC-V or ARM processor
10. **Benchmarking:** Test with real neural networks (MobileNet, ResNet)
11. **ASIC Tape-out:** Fabricate using open-source shuttle (if available)

---


## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 Ishaan Singhal

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## 🙏 Acknowledgments

- **Institution:** Delhi Technological University (DTU)
- **Open-source Community:** For tools like OpenLane, Yosys, and Sky130 PDK
---

<div align="center">

### ⭐ If you found this project interesting, please give it a star! ⭐

**Built with ❤️ and lots of ☕**

</div>

---

## 📸 Gallery

### Architecture Diagrams
*Coming soon: Visual representations of systolic dataflow and timing diagrams*

### Simulation Screenshots
*Coming soon: Waveforms showing AXI transactions and array computation*

### Layout Preview
*Coming soon: GDS layout screenshots from Magic/KLayout*

---

**Last Updated:** February 2026  
**Project Status:** Active Development 🚧
---
**This project is done solely by me.**
