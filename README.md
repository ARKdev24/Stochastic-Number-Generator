# Stochastic-Number-Generator
A hardware-efficient FPGA implementation of a Sobol-Chaotic Hybrid Stochastic Number Generator (SNG) optimized for fast convergence to  be used in BCI applications..

A low-power, FPGA-based Stochastic Number Generator combining a fixed-point chaotic map and a Sobol sequence generator, designed as a foundation for stochastic-computing applications in EEG signal processing and Brain-Computer Interfaces (BCI).

## Overview

Stochastic Computing (SC) represents numbers as probabilities encoded in random bitstreams rather than conventional binary words, enabling extremely simple, low-area, fault-tolerant arithmetic (e.g., single AND gates for multiplication). The quality of any SC system is bottlenecked by its **Stochastic Number Generator (SNG)** — the module responsible for producing bitstreams with low autocorrelation (within a stream) and low cross-correlation (between streams), since correlated bitstreams introduce systematic, non-vanishing bias into downstream SC arithmetic.

This project implements a hybrid SNG that combines:
- A **fixed-point digital chaotic map** (logistic map, r = 4) for a compact, aperiodic entropy source, and
- A **Sobol low-discrepancy sequence generator**, implemented via a trailing-zero-counter/direction-number construction,

XORed together through a bit-interleaving/reversal mixing stage to produce the final stochastic bitstream, gated through a threshold comparator.

The long-term goal is to use this SNG as the randomness source for stochastic-computing-based filters (FIR/IIR) applied to **neural spike detection** in EEG-based BCI and neural prosthesis applications, where low-power, low-area hardware is a hard constraint.

## Motivation

Conventional binary arithmetic hardware for real-time, always-on biomedical signal processing (e.g., wearable EEG/BCI front-ends) is often too power- and area-hungry for edge deployment. Stochastic computing offers a path to drastically simpler arithmetic at the cost of increased bitstream length and some approximation error — a trade-off that may be acceptable given the already-noisy, error-tolerant nature of biomedical signals. This project explores whether a carefully-designed hybrid SNG can achieve correlation and accuracy figures good enough to make that trade-off worthwhile for spike-detection filtering.

## Architecture

The pipeline is implemented in Verilog and targets a Xilinx Artix-7 FPGA (Vivado toolchain).

```
                    ┌─────────────┐     ┌──────────────┐
  chaotic_seed ────▶│  Stage 1     │────▶│  Stage 2      │──┐
                    │  Chaos Map   │     │  Quantizer/   │  │
                    │  (Q2.30,     │     │  Scaler       │  │
                    │   DSP48)     │     │  (<<2)        │  │
                    └─────────────┘     └──────────────┘  │
                                                            ▼
                                                     ┌──────────────┐     ┌────────────┐
                                                     │  Stage 4      │────▶│ Comparator │──▶ bitstream_out
                                                     │  Hybrid Mixer │     │ (vs.       │
                                                     │  (interleave/ │     │ threshold) │
                                                     │   reverse +   │     └────────────┘
                                                     │   XOR)        │
                                                     └──────────────┘
                                                            ▲
                    ┌─────────────┐                        │
                    │  Stage 3     │────────────────────────┘
                    │  Sobol       │
                    │  Sequence    │
                    │  Generator   │
                    └─────────────┘
```

### Stage 1 — Chaos Calculator
Implements one iteration of the logistic map `x_next = 4·x·(1-x)` in Q2.30 fixed-point arithmetic (2 integer bits, 30 fractional bits), using the FPGA's dedicated DSP48 multiplier block for the core multiply. The extra integer-bit headroom (beyond the mathematically-required range) provides a detectable overflow margin — bits [63:60] of the intermediate 64-bit product should always read zero in correct operation; a nonzero value flags an out-of-range excursion. The stage includes zero-seed and zero-collapse guards to prevent the map from locking at a fixed point.

### Stage 2 — Quantizer
Performs a lossless left-shift (`<<2`) to reformat the chaos value from Q2.30 into a full-scale Q0.32 representation suitable for direct comparison, without discarding any information across the map's valid operating range.

### Stage 3 — Sobol Engine
Generates a base-2 (Van der Corput-style) Sobol sequence via a trailing-zero-counter/direction-number construction. **This stage is currently fixed/deterministic** — it has no external seed input and always starts from the same internal state on reset, so it produces the same sequence on every run. See *Known Issues* below.

### Stage 4 — Hybrid Mixer
Combines the chaos and Sobol streams via bit-reversal (on the Sobol stream) and bit-interleaving (on the chaos stream) before XOR-mixing, to spread each source's high-activity bits across the full word width and reduce the chance of residual structure surviving the combination.

### Top-Level Comparator
The final stochastic bit is generated by comparing the hybrid output against a programmable `target_threshold`: `bitstream_out = (final_hybrid_out < target_threshold)`. The probability of a `1` in the output stream is set by where the threshold sits in the 32-bit range — the standard comparator-based SNG architecture.

## Results

Correlation and accuracy were evaluated by capturing bitstreams via testbench simulation and post-processing (autocorrelation/cross-correlation vs. lag and stream length).

| Metric | Bitstream length | Result |
| Autocorrelation | 64 bits | ~10⁻³ |
| Cross-correlation | 64 bits | ~10⁻³ |
| Truncation/target probability accuracy | 64 bits | ~10⁻² |
| Cross-correlation | 100,000 bits | ~10⁻⁵ |

The cross-correlation improvement at longer stream lengths is consistent with the low-discrepancy (quasi-Monte Carlo) convergence properties of the Sobol component, which converges faster than the standard 1/√N Monte Carlo rate for independent-stream statistics.

## Repository Structure

```
├── rtl/
│   └── <top-level Verilog file — chaos map, quantizer, Sobol generator, mixer, comparator>
├── tb/
│   └── <testbench file>
├── constraints/
│   └── <.xdc constraints file>
├── analysis/
│   └── <correlation / analysis script(s)>
└── README.md
```

## Getting Started

### Requirements
- Xilinx Vivado (developed/tested on version `<fill in your version>`)
- Target device: Xilinx Artix-7 (`<fill in exact part number>`)
- Python 3 with NumPy/SciPy (or MATLAB) for post-simulation correlation analysis

### Running the Simulation
1. Open the project in Vivado, or add the RTL and testbench files to a new simulation project.
2. Set the testbench module as the simulation top.
3. For reproducible, non-repeating random seeds across runs, pass an explicit or randomized SystemVerilog seed to the simulator, e.g.:
   ```
   xsim work.<testbench_module> -sv_seed random
   ```
4. Run the simulation — the testbench captures `bitstream_out` to a text file after an initial pipeline-fill delay.
5. Post-process the captured bitstream with the script(s) in `analysis/` to compute autocorrelation, cross-correlation, and probability accuracy.

### Synthesis
The included `.xdc` constraints file targets a 15 ns clock period (~66.7 MHz) with representative I/O delay budgets for board-level integration; adjust as needed for your target board.

## Known Issues / Future Work

- **Sobol stage is unseeded and deterministic.** The current `stage3_sobol` module has no seed input, so it always starts from the same internal state and produces an identical sequence on every reset/run. This means the chaos map is currently the only source of run-to-run variation. Adding an external seed (and/or a whitening mechanism) to the Sobol stage is planned, to both randomize its starting phase and reduce the structural autocorrelation inherent to raw Sobol/Van der Corput sequences when read as a single temporal stream.
- **Autocorrelation at 100,000-bit length not yet measured** — planned as part of characterizing whether the observed correlation figures are limited by statistical sampling noise or by structural/deterministic correlation in the current design.
- **Reset style consistency:** Stage 1 currently uses a synchronous reset while Stages 2–4 use asynchronous resets; unifying this is planned for improved timing-closure robustness.
- **Chaos map edge case:** the x ≈ 0.5 boundary condition (which can transiently produce an out-of-range value under the current scaling) is only partially guarded; a dedicated check is planned.
- **Spike-detection filter integration:** the next milestone is a stochastic-computing FIR/IIR filter using this SNG as its randomness source, validated against synthetic spike waveforms (known-ground-truth spike template + additive noise) for detection accuracy, not just correlation statistics in isolation.
- **Physical entropy source exploration:** early-stage investigation into a physical (avalanche-noise-based) entropy source as an alternative/supplementary seed source, alongside the purely algorithmic chaos/Sobol construction used currently.

## Background / Related Reading

- Alaghi, A. & Hayes, J.P., *Survey of Stochastic Computing*, ACM TECS, 2013.
- Sobol, I.M., low-discrepancy sequence construction (base-2 / Van der Corput direction numbers).
- Standard references on digital chaotic map dynamical degradation under finite-precision (fixed-point) implementation.

## Author

Arnab Karmakar — Electronics & Telecommunication Engineering, Jadavpur University
Research supervised by Dr. Sayan Chatterjee, IC Design and Fabrication Center of Excellence, Dept. of ETCE, Jadavpur University.
