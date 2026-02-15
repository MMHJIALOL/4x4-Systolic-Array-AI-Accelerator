# 4x4 Systolic Array AI Accelerator: Complete RTL-to-GDSII Flow Report

## Project Report

### Hardware Implementation using SkyWater 130nm PDK

**Ishaan Singhal**
Delhi Technological University

---

# Abstract

This report presents the complete design and physical implementation of a 4×4 systolic array-based matrix multiplication accelerator for artificial intelligence workloads. The accelerator is designed to perform INT8 precision matrix operations, which are fundamental to neural network inference.

The project encompasses the entire VLSI design flow from Register Transfer Level (RTL) design in SystemVerilog to the generation of a manufacturable GDSII layout file. The implementation uses the open-source OpenLane toolchain with the SkyWater 130nm Process Design Kit (PDK), demonstrating a complete tape-out ready design with zero DRC/LVS violations and timing closure at 100 MHz.

**Keywords:** Systolic Array, Matrix Multiplication, AI Accelerator, VLSI, RTL-to-GDS, OpenLane, Sky130 PDK

---

# 1. Introduction

## 1.1 Motivation

Matrix multiplication is the fundamental computational kernel in modern artificial intelligence and machine learning applications. Neural network inference, which powers applications from image recognition to natural language processing, requires billions of multiply-accumulate (MAC) operations. Traditional CPU-based implementations are inefficient for these workloads, creating a need for specialized hardware accelerators.

Hardware accelerators achieve significant performance improvements through:

* **Parallelism:** Multiple MAC operations executing simultaneously
* **Optimized Dataflow:** Minimizing memory access and data movement
* **Low Precision:** INT8 arithmetic provides 4× memory/bandwidth improvement over FP32
* **Power Efficiency:** Fixed-function hardware reduces energy per operation

---

## 1.2 Systolic Array Architecture

A systolic array is a homogeneous network of processing elements (PEs) that rhythmically compute and pass data through the structure. The term "systolic" comes from the heart's pumping mechanism—data pulses through the array in a coordinated, wave-like pattern.

**Key Characteristics:**

* **Weight-Stationary Dataflow:** Weights remain fixed in PEs while activations flow through
* **Spatial Parallelism:** All PEs operate simultaneously each clock cycle
* **Pipelined Execution:** Data flows in a staggered pattern through delay registers
* **Scalability:** Array size can be increased for higher throughput

---

## 1.3 Project Objectives

1. Design a 4×4 systolic array capable of INT8 matrix multiplication
2. Implement AXI-Stream interfaces for industry-standard data streaming
3. Complete the full RTL-to-GDSII physical design flow
4. Achieve timing closure at 100 MHz operating frequency
5. Generate a DRC/LVS clean layout ready for fabrication
6. Document the complete design methodology and results

---

# 2. Design Specification and Architecture

## 2.1 System Overview

The AI matrix multiplication accelerator consists of a 4×4 grid of processing elements connected in a systolic topology. The system accepts two 4×4 matrices as input through AXI-Stream interfaces and produces a 4×4 result matrix.

**Top-Level Block Diagram:**

insert image here

---

## 2.2 Design Parameters

| Parameter           | Value                                  |
| ------------------- | -------------------------------------- |
| Array Configuration | 4×4 (16 Processing Elements)           |
| Data Precision      | INT8 (8-bit input, 32-bit accumulator) |
| Target Frequency    | 100 MHz (10 ns period)                 |
| Technology Node     | SkyWater 130 nm                        |
| Interface Protocol  | AXI-Stream (slave)                     |
| Peak Throughput     | 16 MAC ops/cycle = 1.6 GOPS            |
| Input Buffer Size   | 16 bytes (per matrix)                  |
| Latency             | ~27 clock cycles (4×4 matmul)          |

---

## 2.3 Architecture Details

### 2.3.1 Processing Element (PE)

Each PE is the fundamental computational unit, performing one multiply-accumulate operation per clock cycle.

**PE Functionality:**

$$
\text{result_out} = \text{result_out} + (a_in \times b_in)
$$

$$
a_out = a_in
$$

$$
b_out = b_in
$$

insert image here

---

### 2.3.2 Systolic Dataflow with Skewing

The systolic array requires carefully orchestrated data arrival times. Input data must be staggered (skewed) to create the correct wave-like propagation pattern through the array.

**Skewing Strategy:**

* Row 0 (a0): No delay (0 cycles)
* Row 1 (a1): 1-cycle delay register
* Row 2 (a2): 2-cycle delay register
* Row 3 (a3): 3-cycle delay register
* Same pattern for columns (b0-b3)

insert image here

---

### 2.3.3 AXI-Stream Interface

**AXI-Stream Signals:**

* `s_axis_tvalid`
* `s_axis_tready`
* `s_axis_tdata[7:0]`

**Handshaking Protocol:** Data transfer occurs only when both valid and ready are high simultaneously, implementing backpressure flow control.

---

# 3. RTL Design and Implementation

## 3.1 Design Hierarchy

```
top.v (Top-level integration)
  +-- buffer.v (x2) - AXI-Stream input buffers
  |     +-- 16x8-bit memory array
  |     +-- Write pointer logic
  |     +-- Read pointer logic
  |     +-- AXI handshaking
  |
  +-- Delay Registers - Systolic timing skew
  |     +-- a1_d1, a2_d2, a3_d3
  |     +-- b1_d1, b2_d2, b3_d3
  |
  +-- systolic_array.v - 4x4 PE grid
        +-- pe.v (x16) - Processing Elements
              +-- 8x8 multiplier
              +-- 32-bit accumulator
              +-- Data forwarding (a_out, b_out)
```

---

## 3.2 Module Descriptions

### 3.2.1 Processing Element (pe.v)

The PE module implements the core multiply-accumulate functionality with data forwarding.

```verilog
module pe (
    input logic clk,
    input logic rst,

    input logic [7:0] a_in,
    input logic [7:0] b_in,

    output logic [7:0] a_out,
    output logic [7:0] b_out,
    
    output logic [31:0] result_out
);
    
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin  
        a_out <= 8'b0;
        b_out <= 8'b0;
        result_out <= 32'b0;
    end  
    else begin
        a_out <= a_in;
        b_out <= b_in;
        result_out <= result_out + (a_in * b_in);
    end
end
endmodule
```

**Key Features:**

* Synchronous design with clock and reset
* 8-bit input operands (a_in, b_in)
* 32-bit accumulator prevents overflow
* Registered outputs for pipelining
* Data forwarding maintains systolic flow

---

### 3.2.2 Systolic Array (systolic_array.v)

The systolic array module instantiates 16 PEs in a 4×4 grid configuration with proper interconnections.

```verilog
module systolic_array (
    input logic clk, rst,
    input logic [7:0] a0, a1, a2, a3,
    input logic [7:0] b0, b1, b2, b3,
    output logic [31:0] result00, result01, result02, result03,
    output logic [31:0] result10, result11, result12, result13,
    output logic [31:0] result20, result21, result22, result23,
    output logic [31:0] result30, result31, result32, result33
);

// Internal wires
logic [7:0] a00, a01, a02, a03;
logic [7:0] b00, b01, b02, b03;

// PE instantiation example - Row 0
pe pe00 (
    .clk(clk), .rst(rst),
    .a_in(a0), .b_in(b0),
    .a_out(a00), .b_out(b00),
    .result_out(result00)
);

pe pe01 (
    .clk(clk), .rst(rst),
    .a_in(a00), .b_in(b1),
    .a_out(a01), .b_out(b01),
    .result_out(result01)
);

// ... Similar instantiations for all 16 PEs ...

endmodule
```

**Interconnection Strategy:**

* Horizontal connections: PE[i][j].a_out → PE[i][j+1].a_in
* Vertical connections: PE[i][j].b_out → PE[i+1][j].b_in
* Edge PEs receive external inputs
* All PE results exposed as outputs

---

### 3.2.3 AXI-Stream Buffer (buffer.v)

The buffer module implements an AXI-Stream interface with storage and read logic.

```verilog
module buffer (
    input logic clk, rst,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    input logic [31:0] s_axis_tdata,
    output logic [7:0] row0, row1, row2, row3,
    input logic read_enable
);

logic [7:0] mem [0:15];
logic [3:0] write_ptr;
logic full_flag;

assign s_axis_tready = ~full_flag;

// Write logic
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        write_ptr = 0;
        full_flag = 0;
    end else if (s_axis_tvalid && s_axis_tready) begin
        mem[write_ptr] <= s_axis_tdata[7:0];
        write_ptr <= write_ptr + 1;
        if (write_ptr == 15) full_flag <= 1;
    end
end

// Read logic
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        row0 <= 0; row1 <= 0; row2 <= 0; row3 <= 0;
    end else if (read_enable) begin
        row0 <= mem[0]; row1 <= mem[4];
        row2 <= mem[8]; row3 <= mem[12];
    end
end

endmodule
```

**Operation Modes:**

1. Write Mode: Accepts streaming data when valid & ready
2. Full Condition: Deasserts ready when 16 bytes stored
3. Read Mode: Outputs 4 values per cycle when read_enable is high
4. Transpose: Data arranged for column-wise feeding into array

---

### 3.2.4 Top-Level Integration (top.v)

The top module integrates all components and implements the critical delay registers for systolic timing.

```verilog
module top (
    input logic clk, rst,
    input logic s_axis_a_valid, s_axis_b_valid,
    output logic s_axis_a_ready, s_axis_b_ready,
    input logic [7:0] s_axis_a_data, s_axis_b_data,
    input logic start_compute,
    output logic done,
    output logic [31:0] result00, result01, result02, result03
);

logic [7:0] raw_a0, raw_a1, raw_a2, raw_a3;
logic [7:0] raw_b0, raw_b1, raw_b2, raw_b3;

// Delay registers for systolic skewing
logic [7:0] a1_d1;
logic [7:0] a2_d1, a2_d2;
logic [7:0] a3_d1, a3_d2, a3_d3;
logic [7:0] b1_d1;
logic [7:0] b2_d1, b2_d2;
logic [7:0] b3_d1, b3_d2, b3_d3;

endmodule
```

---

## 3.3 Verification and Simulation

### 3.3.1 Testbench Architecture

Comprehensive testbenches were developed at multiple levels of hierarchy.

#### 1. PE-Level Testbench

```verilog
module pe_tb;
reg clk, rst;
reg [7:0] a_in, b_in;
wire [7:0] a_out, b_out;
wire [31:0] result_out;

pe uut (.clk(clk), .rst(rst), .a_in(a_in), .b_in(b_in),
        .a_out(a_out), .b_out(b_out), .result_out(result_out));

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1; #10 rst = 0;
    
    a_in = 3; b_in = 4; #10;
    $display("Result = %d", result_out);
    
    $finish;
end
endmodule
```

---

#### 2. Array-Level Testbench

```verilog
module systolic_tb_4x4;
reg clk, rst;
reg [7:0] a0, a1, a2, a3;
reg [7:0] b0, b1, b2, b3;
wire [31:0] result00, result01, result02, result03;

systolic_array uut (
    .clk(clk), .rst(rst),
    .a0(a0), .a1(a1), .a2(a2), .a3(a3),
    .b0(b0), .b1(b1), .b2(b2), .b3(b3),
    .result00(result00)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1; #10 rst = 0;
    
    a0 = 1; a1 = 2; a2 = 3; a3 = 4;
    b0 = 1; b1 = 0; b2 = 0; b3 = 0;
    
    #500;
    
    $display("Results: %d %d %d %d", result00, result01, result02, result03);
    $finish;
end
endmodule
```

---

#### 3. System-Level Testbench

```verilog
module top_tb;
reg clk, rst;
reg s_axis_a_valid, s_axis_b_valid;
reg [7:0] s_axis_a_data, s_axis_b_data;
reg start_compute;
wire s_axis_a_ready, s_axis_b_ready;
wire done;
wire [31:0] result00, result01, result02, result03;

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

endmodule
```

---

### 3.3.2 Simulation Results

insert image here

**Verification Results:**

* All 16 result values match expected output
* Timing behavior correct (27-cycle latency observed)
* AXI handshaking operates correctly
* No X or Z values in outputs
* Reset functionality verified

---

# 4. Logic Synthesis

## 4.1 Synthesis Flow and Constraints

Logic synthesis transforms the RTL description into a gate-level netlist using standard cells from the SkyWater 130nm PDK.

### 4.1.1 Synthesis Tool and Settings

**Tool:** Yosys (open-source synthesis engine)

**Standard Cell Library:** `sky130_fd_sc_hd` (High-Density standard cells)

**Synthesis Strategy:** Area-optimized (AREA 0 strategy)

insert image here

### 4.1.2 Design Constraints

Synthesis constraints were specified through the OpenLane configuration file:

```json
{
    "DESIGN_NAME": "top",
    "VERILOG_FILES": [
        "dir::src/top.sv",
        "dir::src/control_unit.sv",
        "dir::src/buffer.sv",
        "dir::src/systolic_array.sv",
        "dir::src/pe.sv"
    ],
    "CLOCK_PORT": "clk",
    "CLOCK_PERIOD": 10.0,
    "DIE_AREA": "0 0 600 600",
    "FP_SIZING": "absolute",
    "FP_PDN_VOFFSET": 0,
    "FP_PDN_VPITCH": 30,
    "FP_PDN_HOFFSET": 0,
    "FP_PDN_HPITCH": 30,
    "RUN_LINTER": 0
}
```

**Timing Constraints:**

* Clock period: 10.0 ns (100 MHz target frequency)
* Input delay: 2.0 ns
* Output delay: 2.0 ns

---

## 4.2 Synthesis Results

### 4.2.1 Gate-Level Statistics

| Metric               | Value                         |
| -------------------- | ----------------------------- |
| Total Cells          | 9,900                         |
| Flip-Flops           | 1,146                         |
| Combinational Cells  | 8,754                         |
| Hierarchical Modules | 17 (16 PEs + top)             |
| Chip Area            | 105462.396800 µm² ≈ 0.105 mm² |

*(Source: reports/1-synthesis.AREA_0.stat.rpt)*

**Major Cell Types:**

* Flip-Flops (dfrtp_2, dfxtp_2): 1,146 total
* XNOR gates (xnor2_2): 767 (used in multipliers)
* Buffers (buf_1): 751
* AND/NAND/OR/NOR gates: ~2,900 combined
* Multiplexers (mux2_2): 272

### 4.2.2 Gate-Level Schematic

The synthesis tool generated a gate-level schematic for visualization of the logic structure.

insert image here

**Observations:**

* 8×8 multiplication mapped to combinational logic
* 32-bit accumulator uses flip-flops and adder structure
* Data forwarding paths are simple register-to-register connections
* Clock distribution to all 1,146 flip-flops

---

# 5. Physical Design Implementation

Physical design (backend) transforms the synthesized gate-level netlist into a manufacturable silicon layout. This process includes floorplanning, placement, clock tree synthesis, and routing.

## 5.1 Design Flow Overview

1. Floorplanning: Define die area, place I/O pins, create power grid
2. Placement: Position standard cells in rows within core area
3. Clock Tree Synthesis (CTS): Build balanced clock distribution network
4. Routing: Connect all logic using metal interconnect layers
5. Sign-off: Verify DRC/LVS, extract parasitics, final timing analysis

**Tools Used:**

* OpenLane
* OpenROAD
* TritonRoute
* Magic
* Netgen

---

## 5.2 Floorplanning

### Objectives

Floorplanning establishes the physical framework for the design by defining the die boundary, placing I/O pins, and constructing the Power Distribution Network (PDN).

### Floorplan Specifications

| Parameter               | Value                          |
| ----------------------- | ------------------------------ |
| Die Area                | 600 µm × 600 µm (0.36 mm²)     |
| Core Area               | ~582 µm × 582 µm (0.34 mm²)    |
| Aspect Ratio            | 1.0 (square die)               |
| Core Utilization Target | 50%                            |
| I/O Pin Placement       | Random equidistant (periphery) |
| Power Stripe Pitch      | 30 µm                          |

### Power Distribution Network (PDN)

The PDN ensures uniform power (VDD) and ground (VSS) delivery to all standard cells, minimizing IR drop and electromigration.

**PDN Structure:**

* Power Rings: Surround core area (Metal 4/5)
* Vertical Stripes: Span die height (Metal 4)
* Horizontal Stripes: Span die width (Metal 5)
* Standard Cell Rails: Met1 rails connect cells to stripes via vias

insert image here

---

## 5.3 Standard Cell Placement

### Placement Strategy

Placement assigns physical locations to all standard cells within the core area, optimizing for wire length and routability.

**Tool:** OpenROAD (RePLace + OpenDP)

**Optimization Objectives:**

1. Minimize total wire length (Half-Perimeter Wire Length - HPWL)
2. Avoid routing congestion
3. Respect cell density constraints
4. Maintain timing-driven placement for critical paths

insert image here

insert image here

**Observations:**

* Cells organized in horizontal rows with consistent height
* Dense placement in center with routing channels
* No placement violations or overlaps
* Adequate white space for routing

---

## 5.4 Clock Tree Synthesis (CTS)

### Objectives

Clock Tree Synthesis builds a balanced distribution network to deliver the clock signal to all 1,146 flip-flops with minimal skew and latency.

**Goals:**

* Low Skew: Minimize time difference between fastest/slowest paths
* Balanced Latency: Equal insertion delay to all registers
* Minimal Power: Reduce clock network switching power
* Timing Closure: Maintain setup/hold margins

### CTS Results

| Metric                   | Value   |
| ------------------------ | ------- |
| Total Flip-Flops (Sinks) | 1,146   |
| Clock Skew               | 0.21 ns |
| Min Latency              | 0.77 ns |
| Max Latency              | 1.03 ns |

*(Source: reports/13-cts_sta.skew.rpt)*

insert image here

insert image here

insert image here

**Analysis:**

* Clock skew of 0.21 ns is excellent for 100 MHz operation (2.1% of period)
* Balanced latency distribution provides uniform timing
* Clock tree buffers strengthen signal and reduce slew

---

## 5.5 Routing

### Routing Objectives

Routing connects all placed cells using metal interconnect layers, following design rules to ensure manufacturability.

**Goals:**

* Connect all nets without shorts or opens
* Minimize wire length and via count
* Avoid DRC violations (spacing, width, antenna)
* Meet timing constraints considering wire delay

### Routing Flow

**Two-Stage Process:**

1. Global Routing: Partition die into routing tiles, assign nets to tiles

   * Tool: OpenROAD FastRoute
   * Generates routing guides (approximate paths)

2. Detailed Routing: Create exact metal tracks and vias

   * Tool: TritonRoute
   * Follows guides from global routing
   * Resolves DRC violations iteratively

### Metal Stack (Sky130)

* Li1 (Local Interconnect): Connects cells to routing layers
* Met1: Horizontal routing (lower layers)
* Met2: Vertical routing
* Met3: Horizontal routing (longer distances)
* Met4: Vertical routing + power stripes
* Met5: Horizontal routing + power stripes

insert image here

insert image here

**Observations:**

* Lower layers (Met1/Met2) used for short local connections
* Higher layers (Met4/Met5) used for long-distance routing and power
* Dense routing in array center, sparser at edges
* All DRC violations successfully resolved

---

# 6. Sign-off and Physical Verification

Sign-off is the final validation stage ensuring the layout is correct, manufacturable, and matches the original design intent.

## 6.1 Parasitic Extraction

Before final timing analysis, parasitic resistance and capacitance (RC) of all interconnects must be extracted from the routed layout.

**Tool:** Magic + OpenROAD RCX

**Output Format:** SPEF (Standard Parasitic Exchange Format)

The extracted parasitics are back-annotated into the timing analysis to obtain the most accurate delay predictions for the fabricated chip.

---

## 6.2 Final Static Timing Analysis (STA)

Post-route STA includes extracted parasitics for the most accurate timing prediction.

### Setup Timing Analysis (Max Delay)

Setup timing ensures that data arrives at the destination flip-flop before the clock edge, with sufficient setup time margin.

**Critical Path Identification:**

Startpoint: `_18376_` (rising edge-triggered flip-flop clocked by clk)
Endpoint: `_18369_` (rising edge-triggered flip-flop clocked by clk)
Path Type: max (setup)

### Path Delay Breakdown

| Component                    | Delay (ns) |
| ---------------------------- | ---------- |
| Clock Network Delay (Launch) | 1.41       |
| Source Flip-Flop (CLK → Q)   | 0.52       |
| Combinational Logic Chain    | 5.50       |
| Data Arrival Time            | 7.43       |

The combinational logic path consists of approximately 20 gate stages including:

* Multiplier logic (NAND, AND gates)
* Adder chain for accumulation (OR, XOR, XNOR gates)
* Data forwarding buffers

### Timing Constraint Calculation

| Parameter                     | Value (ns) |
| ----------------------------- | ---------- |
| Clock Period                  | 10.00      |
| Clock Network Delay (Capture) | +1.22      |
| Clock Uncertainty             | -0.25      |
| Clock Reconvergence Pessimism | +0.06      |
| Library Setup Time            | -0.06      |
| Data Required Time            | 10.98      |
| Data Arrival Time             | 7.43       |
| Setup Slack                   | +3.55      |

Slack Calculation:

$$
\text{Setup Slack} = 10.98 - 7.43 = +3.55 \text{ ns}
$$

*(Source: reports/31-rcx_sta_max.rpt)*

The positive slack of 3.55 ns indicates the design has comfortable timing margin at 100 MHz.

Maximum theoretical frequency:

$$
f_{max} = \frac{1}{7.43 \text{ ns}} \approx 134.6 \text{ MHz}
$$

---

### Hold Timing Analysis (Min Delay)

Hold timing ensures that data remains stable at the flip-flop input for a minimum duration after the clock edge.

| Parameter           | Value    |
| ------------------- | -------- |
| Shortest Path Delay | 0.68 ns  |
| Clock Skew          | 0.21 ns  |
| Library Hold Time   | 0.15 ns  |
| Hold Slack          | +0.32 ns |
| Status              | MET      |

*(Source: reports/31-rcx_sta_min.rpt)*

The positive hold slack indicates no hold violations exist in the design.

---

## 6.3 Final Power Analysis

| Component           | Power (mW) | Percentage |
| ------------------- | ---------- | ---------- |
| Sequential Logic    | 11.43      | 44.0%      |
| Combinational Logic | 14.54      | 56.0%      |
| Leakage Power       | 0.000076   | 0.0%       |
| Total Power         | 26.0       | 100%       |

*(Source: reports/31-rcx_sta.power.rpt)*

Power Density:

$$
\text{Power Density} = \frac{26.0 \text{ mW}}{0.36 \text{ mm}^2} = 72.2 \text{ mW/mm}^2
$$

Energy per MAC:

$$
\text{Energy per MAC} = 16.25 \text{ pJ/MAC}
$$

---

## 6.4 Design Rule Check (DRC)

Tool: Magic DRC

Result: ZERO violations

---

## 6.5 Layout vs Schematic (LVS)

Tool: Netgen

Result: 100% MATCH

---

## 6.6 Final GDSII Layout

insert image here

---

# 7. Results and Analysis

## Implementation Summary

| Category     | Parameter              | Value                   |
| ------------ | ---------------------- | ----------------------- |
| Technology   | Process Node           | SkyWater 130 nm         |
| Design Size  | Die Area               | 600 × 600 µm (0.36 mm²) |
| Performance  | Target Clock Frequency | 100 MHz                 |
| Performance  | Peak Throughput        | 1.6 GOPS                |
| Power        | Total Power @ 100 MHz  | 26.0 mW                 |
| Clock        | Clock Skew             | 0.21 ns                 |
| Verification | DRC Violations         | 0                       |
| Verification | LVS Status             | PASSED (100% match)     |
| Status       |                        | TAPE-OUT READY          |

---

# 8. Conclusion

This project successfully demonstrated the complete VLSI design flow from high-level RTL description to manufacturable silicon layout. A 4×4 systolic array-based AI accelerator was designed, verified, and physically implemented using open-source tools and the SkyWater 130nm PDK.

**Key Achievements:**

* Designed a functional 16-PE systolic array for matrix multiplication
* Implemented industry-standard AXI-Stream interfaces
* Completed full RTL-to-GDSII flow with automated tools (OpenLane)
* Achieved timing closure at 100 MHz target frequency
* Generated DRC/LVS clean layout (0 violations)
* Produced tape-out ready GDSII file for fabrication

---



MIT License

Copyright (c) 2026 Ishaan Singhal

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.


---

This project is done solely by me.
---
