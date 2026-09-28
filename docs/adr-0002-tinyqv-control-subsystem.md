# ADR-0002: TinyQV-derived control subsystem

- Status: accepted for v0.2 proof-of-integration branch
- Date: 2026-09-27
- Supersedes: no v0.1 functional decision

## Context

Hasemi v0.1 is a verified autonomous risk accelerator. The v0.2 question is
whether a minimal firmware-capable controller and external memories can coexist
with that accelerator in a 3x2 Tiny Tapeout SKY130 allocation without weakening
v0.1 semantics or sign-off discipline.

## Decision

Use the CPU/memory dependency closure pinned by the TT06 TinyQV project. Keep
program and data memory external on the shared QSPI bus, map Hasemi at
`0x0800_1000`, retain the external SPI register path, and arbitrate the single
register-bank port with external SPI priority. Keep one 10 MHz system clock and
do not import unrelated TinyQV peripherals.

## Consequences

- firmware can configure and monitor the same byte registers already verified
  through SPI;
- Hasemi remains useful even if CPU firmware is absent or fails to boot;
- firmware must use byte MMIO operations in v0.2;
- the board must provide correctly initialized QSPI flash/PSRAM;
- QSPI consumes all eight bidirectional pins;
- physical fit and timing remain open until synthesis and 3x2 hardening finish;
- a failed physical experiment results in FIT WITH REDUCTION or DOES NOT FIT,
  not in relaxed verification/timing requirements.

