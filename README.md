# FPGA-Based Sine Wave Generation and Digital Frequency Mixing

## Overview

This project implements a **Digital Direct Digital Synthesis (DDS)** based sine-wave generator on an **Xilinx Artix-7 FPGA**.

Two independent sine waves with different frequencies are generated using separate DDS blocks. The generated digital sine-wave samples are then multiplied to demonstrate **digital frequency mixing**.

The project is being developed and verified using **AMD/Xilinx Vivado** and is targeted for the **Digilent Arty A7-35T (Artix-7 XC7A35T)** FPGA board.

---

## Project Objectives

- Generate programmable digital sine waves using DDS.
- Implement a reusable DDS module using a phase accumulator and sine LUT.
- Generate two sine waves with different frequencies.
- Perform digital multiplication of the two sine-wave signals.
- Observe and verify the generated signals using Vivado simulation.
- Implement hardware verification using the **Vivado Integrated Logic Analyzer (ILA)**.
- Demonstrate the sum and difference frequency components produced by digital mixing.

---

## System Architecture

```text
                    ┌─────────────────┐
                    │     DDS 1       │
                    │   1 MHz Sine    │
                    └────────┬────────┘
                             │
                             │ sine1
                             ▼
                        ┌──────────┐
                        │          │
                        │          │
                        │    ×     │──────► Product
                        │          │
                        │          │
                        └────▲─────┘
                             │
                             │ sine2
                    ┌────────┴────────┐
                    │     DDS 2       │
                    │   3 MHz Sine    │
                    └─────────────────┘

                             │
                             ▼
                            ILA
