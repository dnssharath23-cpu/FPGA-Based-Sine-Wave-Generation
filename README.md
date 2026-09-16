# FPGA-Based Sine Wave Generation and Digital Frequency Mixing

## 📌 Project Overview

This project implements a **Digital Direct Digital Synthesis (DDS)** based sine-wave generation system on an **AMD/Xilinx Artix-7 FPGA**.

The design generates two independent digital sine waves at different frequencies using two DDS blocks. The generated signals are then converted from unsigned offset-binary representation to signed zero-centered samples and multiplied digitally.

The multiplication demonstrates the fundamental operation of a **digital frequency mixer**, where multiplication of two sinusoidal signals produces new frequency components corresponding to the **sum and difference of the original frequencies**.

The current implementation targets the **Digilent Arty A7-35T development board**, which uses the **Xilinx Artix-7 XC7A35T FPGA**.

The design is developed and verified using **AMD/Xilinx Vivado**, with behavioral simulation performed using **Vivado XSim**. Hardware-level verification is planned using the **Vivado Integrated Logic Analyzer (ILA)**.

---

# 🎯 Project Objectives

The main objectives of this project are:

1. Implement a reusable Digital Direct Digital Synthesis (DDS) module.
2. Generate digital sine waves using a phase accumulator and lookup table.
3. Generate two sine waves with independently configurable frequencies.
4. Implement a 32-bit phase accumulator for fine frequency resolution.
5. Use a 1024-entry sine-wave lookup table.
6. Generate 12-bit digital sine-wave samples.
7. Convert the unsigned offset-binary DDS output into a signed zero-centered representation.
8. Perform signed digital multiplication of the two sine waves.
9. Demonstrate the frequency-mixing principle using FPGA digital logic.
10. Verify the design using Vivado behavioral simulation.
11. Verify the implemented design on the Artix-7 FPGA using Vivado ILA.
12. Study the possibility of producing analog outputs using an external DAC in future work.

---

# 🧩 System Architecture

The overall system consists of two independent DDS generators followed by a digital multiplier.

```text
                         ┌─────────────────────┐
                         │       DDS 1         │
                         │                     │
                         │ Phase Accumulator   │
                         │        +            │
                         │   Sine LUT          │
                         └──────────┬──────────┘
                                    │
                                    │  sine1
                                    ▼
                              ┌────────────┐
                              │            │
                              │  Signed    │
                              │ Conversion │
                              │            │
                              └─────┬──────┘
                                    │
                                    │
                                    ▼
                              ┌────────────┐
                              │            │
                              │ Multiplier │──────► product
                              │            │
                              └─────▲──────┘
                                    │
                                    │
                              ┌─────┴──────┐
                              │            │
                              │  Signed    │
                              │ Conversion │
                              │            │
                              └─────┬──────┘
                                    ▲
                                    │ sine2
                                    │
                         ┌──────────┴──────────┐
                         │       DDS 2         │
                         │                     │
                         │ Phase Accumulator   │
                         │        +            │
                         │   Sine LUT          │
                         └─────────────────────┘
```

Both DDS blocks use the same 100 MHz FPGA system clock but have different Frequency Control Words (FCWs), allowing them to generate different output frequencies.

---

# 🔬 Direct Digital Synthesis (DDS)

## What is DDS?

**Direct Digital Synthesis (DDS)** is a digital technique used to generate periodic waveforms such as sine waves using a digital phase accumulator and a waveform lookup table.

Instead of calculating the sine function continuously, the DDS system:

1. Generates a continuously increasing digital phase.
2. Uses the most significant bits of the phase as an address.
3. Reads the corresponding amplitude value from a sine lookup table.
4. Produces a digital approximation of the desired sine wave.

The basic DDS structure is:

```text
Frequency Control Word
          │
          ▼
   ┌───────────────┐
   │     Phase     │
   │   Accumulator │
   └───────┬───────┘
           │
           │ Phase
           ▼
   ┌───────────────┐
   │  Phase → ROM  │
   │    Address    │
   └───────┬───────┘
           │
           ▼
   ┌───────────────┐
   │    Sine LUT   │
   └───────┬───────┘
           │
           ▼
      Digital Sine
```

---

# 📐 DDS Frequency Equation

The output frequency of a DDS is determined by:

\[
f_{out} =
\frac{FCW}{2^N}f_{clk}
\]

where:

- \(f_{out}\) = desired output frequency
- \(FCW\) = Frequency Control Word
- \(N\) = phase accumulator width
- \(f_{clk}\) = system clock frequency

The Frequency Control Word is therefore calculated as:

\[
FCW =
\frac{f_{out}2^N}{f_{clk}}
\]

In this project:

\[
N=32
\]

and

\[
f_{clk}=100\,MHz
\]

Therefore:

\[
FCW =
\frac{f_{out}\times2^{32}}{100\times10^6}
\]

---

# ⚙️ DDS Configuration

The current DDS implementation uses the following configuration:

| Parameter | Value |
|---|---:|
| FPGA Clock | 100 MHz |
| Phase Accumulator | 32 bits |
| Sine LUT Entries | 1024 |
| LUT Address | 10 bits |
| Sine Amplitude Resolution | 12 bits |
| DDS Output | 12 bits |

A 32-bit phase accumulator provides very fine frequency resolution.

The phase accumulator wraps around automatically when it reaches its maximum value.

---

# 🔢 Phase Accumulator

The phase accumulator performs:

```verilog
phase_acc <= phase_acc + fcw;
```

on every rising edge of the FPGA clock.

Conceptually:

```text
             FCW
              │
              ▼
       ┌──────────────┐
       │              │
       │ Phase        │
       │ Accumulator  │
       │              │
       └──────┬───────┘
              │
              │ 32-bit phase
              ▼
        phase_acc[31:22]
              │
              ▼
       10-bit LUT address
              │
              ▼
          Sine ROM
```

Since the LUT contains 1024 entries:

\[
1024=2^{10}
\]

the upper 10 bits of the 32-bit phase accumulator are used as the LUT address:

```verilog
sine_rom[phase_acc[31:22]]
```

This allows one complete sine-wave cycle to be represented using 1024 amplitude samples.

---

# 🌊 Sine Lookup Table

A sine lookup table is used instead of calculating the sine function directly in hardware.

The LUT contains:

```text
1024 samples
12-bit amplitude resolution
```

The values represent one complete sine-wave cycle.

The LUT is stored in a memory initialization file:

```text
sine_lut.mem
```

The DDS module loads this file using:

```verilog
$readmemh("sine_lut.mem", sine_rom);
```

The LUT is generated using Python.

---

# 🐍 LUT Generation Using Python

The sine lookup table is generated offline using Python.

The Python script calculates the sine value for each of the 1024 phase positions and converts the result into a 12-bit unsigned value.

The basic generation process is:

```python
import math

LUT_SIZE = 1024
DAC_BITS = 12

MAX_VALUE = (2 ** DAC_BITS) - 1
MID_VALUE = MAX_VALUE / 2
AMPLITUDE = MAX_VALUE / 2

with open("sine_lut.mem", "w") as file:
    for i in range(LUT_SIZE):

        angle = 2.0 * math.pi * i / LUT_SIZE

        value = MID_VALUE + AMPLITUDE * math.sin(angle)

        value = int(round(value))

        value = max(0, min(MAX_VALUE, value))

        file.write(f"{value:03X}\n")
```

Python is used only to generate the LUT file.

The Python program itself does **not run on the FPGA**.

Vivado/XSim reads the generated `.mem` file during simulation, and the synthesized design can use the initialized ROM.

---

# 🔢 Offset-Binary Representation

The generated DDS sine wave uses a 12-bit unsigned representation.

Therefore the output range is:

```text
0       → negative peak
2048    → approximately zero
4095    → positive peak
```

Conceptually:

```text
       +2047
          │
          │       /\
          │      /  \
       2048 ────/────\────  Zero level
          │   /        \
          │  /          \
          │ /
          │
          0
```

This representation is useful when interfacing with an unsigned DAC.

However, it is not directly suitable for mathematical signed multiplication because the sine wave is not centered around zero in its digital representation.

---

# ➖ Conversion to Signed Sine Samples

To perform a mathematically correct multiplication, the DC offset of 2048 is removed.

The conversion is:

\[
x_{signed}=x_{unsigned}-2048
\]

Therefore:

```text
Unsigned DDS output:

0 ... 2048 ... 4095

        │
        │ subtract 2048
        ▼

Signed output:

-2048 ... 0 ... +2047
```

The conversion is implemented as:

```verilog
assign sine1 = $signed({1'b0, sine1_raw}) - 13'sd2048;
assign sine2 = $signed({1'b0, sine2_raw}) - 13'sd2048;
```

The extra bit is used because the signed representation must accommodate both positive and negative values.

---

# 🎛️ Two Independent DDS Generators

The same reusable DDS module is instantiated twice.

```text
DDS 1
FCW1 → 1 MHz sine wave

DDS 2
FCW2 → 3 MHz sine wave
```

This demonstrates that the DDS module can be reused for multiple frequencies.

The current configuration is:

| DDS | Frequency | FCW |
|---|---:|---:|
| DDS 1 | 1 MHz | 42,949,673 |
| DDS 2 | 3 MHz | 128,849,019 |

For a 100 MHz clock and 32-bit phase accumulator:

### DDS 1

\[
FCW_1 =
\frac{1MHz\times2^{32}}{100MHz}
\]

\[
FCW_1 \approx 42,949,673
\]

### DDS 2

\[
FCW_2 =
\frac{3MHz\times2^{32}}{100MHz}
\]

\[
FCW_2 \approx 128,849,019
\]

---

# 💻 Reusable DDS Module

The DDS module accepts the Frequency Control Word as an input.

```verilog
module sine_dds (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] fcw,
    output reg  [11:0] sine_out
);

    reg [31:0] phase_acc;
    reg [11:0] sine_rom [0:1023];

    initial begin
        $readmemh("sine_lut.mem", sine_rom);
    end

    always @(posedge clk) begin
        if (rst)
            phase_acc <= 32'd0;
        else
            phase_acc <= phase_acc + fcw;
    end

    always @(posedge clk) begin
        if (rst)
            sine_out <= 12'd2048;
        else
            sine_out <= sine_rom[phase_acc[31:22]];
    end

endmodule
```

The module is reusable because the frequency is controlled through the `fcw` input instead of being hard-coded inside the module.

---

# ✖️ Digital Multiplication

After generating the two sine waves, they are multiplied.

The centered signed samples are:

\[
x_1[n]
\]

and

\[
x_2[n]
\]

The output is:

\[
y[n]=x_1[n]x_2[n]
\]

The Verilog implementation is:

```verilog
assign product = sine1 * sine2;
```

Because each sine sample is represented using 13 signed bits:

```text
13-bit × 13-bit = 26-bit
```

Therefore the product is declared as:

```verilog
wire signed [25:0] product;
```

Using 26 bits prevents loss of the multiplication result.

---

# 🎚️ Why Signed Multiplication is Required

If the original unsigned DDS values were multiplied directly:

```verilog
assign product = sine1_raw * sine2_raw;
```

the result would contain a large DC offset because both signals are centered around 2048 rather than zero.

Mathematically:

\[
x_1=2048+A\sin(\omega_1t)
\]

\[
x_2=2048+A\sin(\omega_2t)
\]

Direct multiplication therefore produces additional DC and frequency terms.

For the intended frequency-mixer operation, the signals must first be centered:

\[
x_1=A\sin(\omega_1t)
\]

\[
x_2=A\sin(\omega_2t)
\]

and then:

\[
y=x_1x_2
\]

This is why the 2048 offset is removed before multiplication.

---

# 📡 Frequency Mixing Theory

The multiplication of two sinusoidal signals produces sum and difference frequency components.

Consider:

\[
x_1(t)=A\sin(2\pi f_1t)
\]

and:

\[
x_2(t)=A\sin(2\pi f_2t)
\]

Their product is:

\[
y(t)=x_1(t)x_2(t)
\]

Using the trigonometric identity:

\[
\sin(A)\sin(B)
=
\frac{1}{2}
[\cos(A-B)-\cos(A+B)]
\]

we obtain:

\[
y(t)=
\frac{A^2}{2}
[
\cos(2\pi(f_1-f_2)t)
-
\cos(2\pi(f_1+f_2)t)
]
\]

Therefore the output contains two major frequency components:

\[
f_{difference}=|f_1-f_2|
\]

and:

\[
f_{sum}=f_1+f_2
\]

---

# 📊 Current Frequency Configuration

The project currently uses:

```text
f1 = 1 MHz
f2 = 3 MHz
```

Therefore:

\[
f_{difference}=3MHz-1MHz
\]

\[
\boxed{f_{difference}=2MHz}
\]

and:

\[
f_{sum}=3MHz+1MHz
\]

\[
\boxed{f_{sum}=4MHz}
\]

Therefore, the product signal contains frequency components at approximately:

```text
2 MHz
4 MHz
```

This is the main frequency-mixing result being demonstrated by the project.

---

# 🌊 Expected Time-Domain Waveforms

The individual DDS outputs are sinusoidal.

The first waveform is:

```text
1 MHz sine wave
```

The second waveform is:

```text
3 MHz sine wave
```

The product is **not expected to be another simple single-frequency sine wave**.

Instead, it is the combination of the sum and difference frequency components.

Conceptually:

```text
1 MHz sine
        \
         \
          × ─────► Mixed/Product waveform
         /
        /
3 MHz sine
```

The product waveform therefore has a more complex shape.

This behavior is expected from the mathematical identity:

\[
\sin(\omega_1t)\sin(\omega_2t)
=
\frac{1}{2}
[
\cos((\omega_1-\omega_2)t)
-
\cos((\omega_1+\omega_2)t)
]
\]

---

# 🧪 MATLAB Reference Verification

Before implementing the multiplication in FPGA hardware, the mathematical behavior can be verified using MATLAB.

For example:

```matlab
Fs = 10000;

t = 0:1/Fs:0.01;

f1 = 100;
f2 = 700;

x1 = sin(2*pi*f1*t);
x2 = sin(2*pi*f2*t);

y = x1 .* x2;

figure;
plot(t,x1);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('Sine Wave 1 - 100 Hz');

figure;
plot(t,x2);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('Sine Wave 2 - 700 Hz');

figure;
plot(t,y);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('Multiplication of 100 Hz and 700 Hz Sine Waves');
```

For this example:

\[
f_1=100Hz
\]

\[
f_2=700Hz
\]

the resulting product contains:

\[
700-100=600Hz
\]

and:

\[
700+100=800Hz
\]

The MATLAB waveform is used as a mathematical reference for the FPGA implementation.

---

# 🖥️ Vivado Behavioral Simulation

The design is first verified through behavioral simulation in Vivado.

The simulation observes:

```text
clk
rst
sine1
sine2
product
```

The expected behavior is:

```text
sine1  → 1 MHz digital sine
sine2  → 3 MHz digital sine
product → signed multiplication of sine1 and sine2
```

The simulation confirms that the DDS blocks generate signals at different frequencies and that the multiplier produces the corresponding combined waveform.

---

# ⏱️ FPGA Clock and Frequency Relationship

The Arty A7-35T provides a 100 MHz system clock for the design.

Therefore:

\[
T_{clk}=\frac{1}{100MHz}=10ns
\]

The 1 MHz sine wave has a period of:

\[
T_1=\frac{1}{1MHz}=1\mu s
\]

The 3 MHz sine wave has a period of:

\[
T_2=\frac{1}{3MHz}\approx333.33ns
\]

Therefore, over approximately 1 microsecond:

- the 1 MHz waveform completes approximately 1 cycle
- the 3 MHz waveform completes approximately 3 cycles

This relationship can be observed in the Vivado simulation waveform.

---

# 🖥️ Hardware Platform

The project targets the:

**Digilent Arty A7-35T FPGA development board**

with the:

**Xilinx/AMD Artix-7 XC7A35T FPGA**

The board provides a 100 MHz clock source that is used as the DDS system clock.

---

# 🔌 Hardware Constraints

The current design only requires external FPGA pin assignments for the system clock and reset.

The internal signals:

```text
sine1
sine2
product
```

do not need physical FPGA pins when they are being observed using ILA.

The clock is assigned to the Arty A7 clock pin:

```text
E3
```

The reset input is connected to:

```text
BTN0 / D9
```

Example XDC:

```tcl
## 100 MHz Clock

set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports clk]

create_clock -add -name sys_clk_pin \
    -period 10.00 \
    -waveform {0 5} \
    [get_ports clk]


## Reset / BTN0

set_property -dict { PACKAGE_PIN D9 IOSTANDARD LVCMOS33 } [get_ports rst]
```

---

# 🔍 Hardware Verification Using ILA

After simulation, the design can be implemented on the Artix-7 FPGA.

The **Vivado Integrated Logic Analyzer (ILA)** can be used to observe the internal digital signals.

The proposed ILA configuration is:

| Signal | Width |
|---|---:|
| `sine1` | 13 bits |
| `sine2` | 13 bits |
| `product` | 26 bits |

The ILA clock is the same 100 MHz system clock.

The hardware architecture becomes:

```text
                 ┌───────────────┐
                 │     DDS 1     │
                 │     1 MHz     │
                 └───────┬───────┘
                         │
                       sine1
                         │
                         ├─────────────┐
                         │             │
                         ▼             │
                    ┌─────────┐       │
                    │         │       │
                    │Multiply │───────┤
                    │         │       │
                    └─────────┘       │
                         │             │
                      product          │
                         │             │
                         ▼             │
                       ┌─────┐         │
                       │ ILA │         │
                       └─────┘         │
                                       │
                 ┌───────────────┐     │
                 │     DDS 2     │     │
                 │     3 MHz     │     │
                 └───────┬───────┘     │
                         │             │
                       sine2 ──────────┘
```

ILA allows the digital waveforms to be observed directly inside the FPGA.

---

# ❓ Why an External DAC is Not Required for ILA

The Arty A7-35T contains an onboard XADC for analog-to-digital conversion, but it does not provide an onboard general-purpose DAC for converting these generated digital signals into analog voltages.

However, a DAC is **not required for the current FPGA verification stage**.

ILA directly monitors the digital signals inside the FPGA.

Therefore:

```text
DDS → Multiplier → ILA
```

is sufficient for digital hardware verification.

An external DAC would only be required if the objective is to produce an actual analog voltage waveform that can be observed using an oscilloscope or spectrum analyzer.

---

# 🎛️ Future External DAC Implementation

A future version of the project can include an external DAC.

The architecture would become:

```text
DDS 1 ─────► sine1 ──────┐
                         │
DDS 2 ─────► sine2 ──────┼──► Digital Processing
                         │
                         ▼
                      product
                         │
                         ▼
                    DAC Interface
                         │
                         ▼
                  External DAC
                         │
                         ▼
              Analog Reconstruction
                         │
                         ▼
              Oscilloscope / Analyzer
```

If the product is sent to a 12-bit DAC, the signed 26-bit product must first be appropriately scaled and converted into the DAC's input range.

The product should **not** simply be truncated to the lowest 12 bits because that can introduce severe distortion and incorrect amplitude representation.

---

# 🧮 Product Data Width

The DDS output is 12-bit unsigned.

After centering:

```text
sine1 = 13-bit signed
sine2 = 13-bit signed
```

The multiplication therefore requires:

\[
13\times13=26
\]

bits.

Hence:

```verilog
output wire signed [25:0] product;
```

The product is signed because multiplication of two signed sine-wave samples produces both positive and negative values.

---

# 📁 Project Structure

The repository is organized to separate RTL, simulation, constraints, LUT data, and reference MATLAB/Python files.

```text
FPGA-Based-Sine-Wave-Generation/
│
├── README.md
│
├── rtl/
│   ├── sine_dds.v
│   └── top.v
│
├── simulation/
│   └── top_tb.v
│
├── lut/
│   └── sine_lut.mem
│
├── constraints/
│   └── arty_a7_35t.xdc
│
├── matlab/
│   └── sine_multiplication.m
│
└── python/
    └── generate_sine_lut.py
```

The exact directory organization may change as the project develops.

---

# 🧱 Main RTL Modules

## `sine_dds.v`

Implements the reusable DDS block.

Main functions:

- 32-bit phase accumulation
- Frequency Control Word input
- 1024-entry sine ROM
- 12-bit sine output
- Reset control

---

## `top.v`

Instantiates two DDS modules.

Main functions:

- Generate 1 MHz sine wave
- Generate 3 MHz sine wave
- Convert both outputs to signed zero-centered values
- Multiply the two signals
- Produce a 26-bit signed product

---

## `top_tb.v`

Used for behavioral simulation.

The testbench provides:

- 100 MHz clock
- Reset sequence
- Simulation duration

and observes:

```text
sine1
sine2
product
```

---

# 📋 Current `top.v` Architecture

The current top-level architecture is:

```verilog
module top (
    input  wire clk,
    input  wire rst,

    output wire signed [12:0] sine1,
    output wire signed [12:0] sine2,
    output wire signed [25:0] product
);

    localparam [31:0] FCW1 = 32'd42949673;
    localparam [31:0] FCW2 = 32'd128849019;

    wire [11:0] sine1_raw;
    wire [11:0] sine2_raw;

    sine_dds dds1 (
        .clk      (clk),
        .rst      (rst),
        .fcw      (FCW1),
        .sine_out (sine1_raw)
    );

    sine_dds dds2 (
        .clk      (clk),
        .rst      (rst),
        .fcw      (FCW2),
        .sine_out (sine2_raw)
    );

    assign sine1 =
        $signed({1'b0, sine1_raw}) - 13'sd2048;

    assign sine2 =
        $signed({1'b0, sine2_raw}) - 13'sd2048;

    assign product =
        sine1 * sine2;

endmodule
```

---

# 🔄 Complete Data Flow

The complete digital processing chain is:

```text
                    100 MHz Clock
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
        ┌───────────┐         ┌───────────┐
        │   DDS 1   │         │   DDS 2   │
        │           │         │           │
        │  FCW1     │         │  FCW2     │
        │  1 MHz    │         │  3 MHz    │
        └─────┬─────┘         └─────┬─────┘
              │                     │
              ▼                     ▼
        12-bit raw             12-bit raw
        sine1                  sine2
              │                     │
              ▼                     ▼
          - 2048                 - 2048
              │                     │
              ▼                     ▼
        13-bit signed         13-bit signed
              │                     │
              └─────────┬───────────┘
                        │
                        ▼
                  13 × 13 Multiply
                        │
                        ▼
                  26-bit signed
                     product
                        │
                        ▼
                       ILA
```

---

# 📈 Expected Frequency-Domain Result

For:

```text
f1 = 1 MHz
f2 = 3 MHz
```

the product should contain:

```text
Difference frequency = 2 MHz
Sum frequency        = 4 MHz
```

A frequency-domain analysis of the product should therefore show significant components around:

```text
2 MHz
4 MHz
```

The exact amplitudes depend on the digital amplitude scaling, LUT quantization, and subsequent processing.

---

# ⚠️ Important Implementation Considerations

## 1. Product is not a single sine wave

The multiplication of two different-frequency sine waves does not result in one sine wave.

It produces the sum and difference frequencies.

Therefore, the product waveform should not be judged by whether it visually resembles a single sine wave.

---

## 2. DDS output is offset binary

The raw DDS output is centered around 2048.

Therefore, direct unsigned multiplication is not equivalent to multiplying two mathematical sine waves centered at zero.

The 2048 offset must be removed before multiplication.

---

## 3. Product must be signed

The product can be positive or negative.

Therefore:

```verilog
signed [25:0]
```

is used.

---

## 4. Product width must be sufficient

A 13-bit signed value multiplied by another 13-bit signed value requires up to 26 bits.

Therefore:

```verilog
[25:0]
```

is used instead of:

```verilog
[23:0]
```

to avoid unnecessary truncation.

---

## 5. ILA observes digital data

ILA does not produce an analog voltage.

It displays the internal FPGA data values.

Therefore:

```text
ILA → Digital waveform observation
DAC → Analog waveform generation
```

---

# 🧪 Verification Strategy

The project follows a staged verification process.

### Stage 1 — MATLAB Verification

Verify the mathematical multiplication of two sine waves.

```text
Sine 1
   +
Sine 2
   ↓
Multiplication
   ↓
Sum + Difference frequencies
```

---

### Stage 2 — Vivado Behavioral Simulation

Verify:

- DDS operation
- Frequency relationship
- Sine LUT operation
- Signed conversion
- Digital multiplication

---

### Stage 3 — RTL Synthesis

Verify that the RTL can be synthesized for the Artix-7 FPGA.

Resource utilization and inferred hardware can be examined after synthesis.

---

### Stage 4 — Implementation

Perform:

- Placement
- Routing
- Timing analysis

for the Artix-7 XC7A35T device.

---

### Stage 5 — Hardware Programming

Generate the bitstream and program the Arty A7-35T.

---

### Stage 6 — ILA Hardware Verification

Use ILA to observe:

```text
sine1
sine2
product
```

and compare the hardware behavior against simulation.

---

### Stage 7 — External DAC

As a future extension, connect an external DAC to produce analog output.

---

# 📊 Project Status

## Completed

- [x] Project architecture defined
- [x] DDS architecture implemented
- [x] 32-bit phase accumulator implemented
- [x] 1024-entry sine LUT generated
- [x] 12-bit sine-wave generation implemented
- [x] Programmable FCW DDS module implemented
- [x] Two DDS instances implemented
- [x] 1 MHz sine-wave generation
- [x] 3 MHz sine-wave generation
- [x] Signed zero-centered conversion
- [x] 26-bit signed digital multiplication
- [x] MATLAB reference verification
- [x] Vivado behavioral simulation
- [x] Artix-7 XC7A35T target selected
- [x] Arty A7-35T clock/reset constraints prepared

## In Progress

- [ ] ILA integration
- [ ] Synthesis
- [ ] Implementation
- [ ] Bitstream generation
- [ ] Programming Arty A7-35T
- [ ] Hardware ILA capture
- [ ] Hardware versus simulation comparison

## Future Work

- [ ] Frequency-spectrum analysis
- [ ] External DAC interface
- [ ] Analog waveform observation
- [ ] Oscilloscope verification
- [ ] Spectrum analyzer verification
- [ ] Programmable frequency input
- [ ] Amplitude control
- [ ] Digital filtering
- [ ] Resource and timing optimization

---

# 🚀 Future Improvements

The DDS architecture can be extended to provide programmable frequency control.

Instead of defining the FCW using constants:

```verilog
localparam [31:0] FCW1 = 32'd42949673;
localparam [31:0] FCW2 = 32'd128849019;
```

the FCW can eventually be provided through:

- switches
- UART
- AXI interface
- processor control
- memory-mapped registers
- external control logic

This would allow the frequency of each DDS to be changed without modifying the RTL.

---

# 📚 Key Concepts Demonstrated

This project combines several important digital design and DSP concepts:

- Digital Direct Digital Synthesis
- Phase accumulation
- Frequency Control Word
- Lookup-table based waveform generation
- Fixed-point digital representation
- Offset-binary representation
- Signed arithmetic
- FPGA digital multiplication
- Frequency mixing
- Sum and difference frequencies
- RTL design
- Behavioral simulation
- FPGA synthesis
- FPGA implementation
- Hardware debugging using ILA
- FPGA-based DSP

---

# 🧠 Technical Summary

The project generates two digital sine waves using independent DDS blocks.

The DDS uses a:

```text
100 MHz clock
32-bit phase accumulator
1024-entry sine LUT
12-bit amplitude
```

The two current output frequencies are:

```text
DDS 1 = 1 MHz
DDS 2 = 3 MHz
```

The unsigned DDS outputs are converted into signed zero-centered samples by subtracting 2048.

The resulting signals are multiplied using a 26-bit signed multiplier.

Mathematically:

\[
\sin(2\pi f_1t)\sin(2\pi f_2t)
=
\frac{1}{2}
[
\cos(2\pi(f_1-f_2)t)
-
\cos(2\pi(f_1+f_2)t)
]
\]

For:

\[
f_1=1MHz
\]

and:

\[
f_2=3MHz
\]

the output contains:

\[
\boxed{2MHz}
\]

and:

\[
\boxed{4MHz}
\]

frequency components.

The digital signals can be verified inside the Artix-7 FPGA using the Vivado Integrated Logic Analyzer without requiring an external DAC.

---

# 🏁 Final Project Flow

```text
                     MATLAB
                       │
                       │ Mathematical Verification
                       ▼
                ┌──────────────┐
                │     DDS      │
                │ Architecture │
                └──────┬───────┘
                       │
                       ▼
               Vivado Simulation
                       │
                       ▼
              ┌─────────────────┐
              │   DDS 1 - 1MHz  │
              └────────┬────────┘
                       │
                       │
                       ▼
                  Signed Data
                       │
                       │
                       ├──────────────┐
                       │              │
                       │              ▼
                       │         ┌──────────┐
                       │         │          │
                       │         │ Multiply │
                       │         │          │
                       │         └────┬─────┘
                       │              │
                       │              ▼
                       │           Product
                       │              │
                       │              ▼
                       │             ILA
                       │
                       │
              ┌────────┴────────┐
              │   DDS 2 - 3MHz │
              └─────────────────┘
                       │
                       ▼
                  Signed Data

                         │
                         ▼
               Hardware Verification
                         │
                         ▼
                 Future External DAC
                         │
                         ▼
                 Analog Observation
```

---

# 👨‍💻 Author

**Sharath Chandra**

Electronics and Communication Engineering

This project is developed as an academic FPGA/DSP implementation for studying digital waveform generation, frequency mixing, and FPGA-based signal processing.

---

# 📜 License

This project is intended for academic, educational, and research purposes.
