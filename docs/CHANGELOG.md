# Changelog

## v0.2 development

### 2026-09-27 - integration plan

- branched `design/hasemi-v0.2-tinyqv` from golden v0.1 commit
  `44ae9879e6f25999b8569dbe8b5acdf4e2fd1a9a`;
- recorded exact v0.1 CI/GDS/GLS/precheck evidence;
- pinned TinyQV TT06 repository commit and core submodule provenance;
- accepted the minimal CPU/QSPI/MMIO architecture in ADR-0002;
- reserved Hasemi MMIO window `0x0800_1000`-`0x0800_107F`;
- documented v0.2 pin map, reset policy, license plan and verification matrix.

### 2026-09-27 - CPU, MMIO and QSPI integration

- imported the byte-identical nine-file TinyQV CPU/QSPI dependency closure;
- added the `0x0800_1000` byte-native Hasemi MMIO bridge;
- retained the external SPI register path with synchronized SPI-transaction
  priority over CPU MMIO;
- mapped shared external QSPI flash/PSRAM to all eight `uio` pins;
- forced deterministic safe QSPI output/output-enable values during reset;
- updated Tiny Tapeout source and pin metadata without adding unrelated
  peripherals or synthesized program/data RAM.
