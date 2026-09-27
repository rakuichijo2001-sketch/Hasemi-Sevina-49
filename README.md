# Hasemi-Sevina-49

**Hasemi-Sevina-49** is an experimental digital ASIC for a field monitoring node. The first real RTL revision is a **configurable multi-sensor edge risk and safety processor** intended to sit between digitized field sensors and an external MCU/gateway.

Target shuttle: **Tiny Tapeout SKY26d / SKY130**, reserved target size **3×2 tiles**.

## What the chip does

The ASIC does not connect directly to analog sensors and does not implement 5G, LoRaWAN, Starlink, cloud software or a general-purpose MCU. Those functions stay outside the chip.

The chip receives digitized measurements through SPI, validates the measurement set, classifies each sensor against configurable watch/critical thresholds, fuses the severities with configurable weights, applies persistence filtering, records events and produces deterministic local status outputs.

Current v0.1 channels:

- rainfall / accumulated rain indicator;
- water-related indicator (for example soil-water or pore-pressure value after digitization);
- tilt indicator;
- displacement indicator.

Current states:

- `NORMAL`
- `WATCH`
- `WARNING`
- `CRITICAL`

A separate `SENSOR_FAULT` path covers missing required data, stale data, an external fault input and invalid threshold ordering.

## Architecture

```text
Digitized sensors / field MCU
            |
            | SPI
            v
+-------------------------------------------+
| Hasemi-Sevina-49                          |
|                                           |
| SPI register interface                    |
|      -> sensor/config register bank       |
|      -> data-valid + stale-data checker   |
|      -> per-sensor severity classifier    |
|      -> weighted risk fusion              |
|      -> persistence-filtered risk FSM     |
|      -> event/IRQ logger                   |
|                                           |
| outputs: WATCH/WARNING/CRITICAL/FAULT/IRQ |
+-------------------------------------------+
            |
            v
External MCU / local alarm / gateway
            |
      LoRaWAN / 4G/5G / satellite
            |
            v
Cloud / GIS / Digital Twin / IOC
```

## SPI protocol

SPI Mode 0. The system clock target is 10 MHz and the initial interface target is SPI <= 2 MHz.

Each transaction is 16 SCLK cycles:

```text
byte 0: [R/W][A6:A0]
byte 1: [D7:D0]
```

- `R/W=1`: write byte 1 to register `A6:A0`.
- `R/W=0`: byte 1 shifted out on MISO is the selected register value.
- A complete sensor set is accepted by writing `0xA5` to `COMMIT` (`0x0D`).

See [`docs/register-map.md`](docs/register-map.md).

## Repository state

The original Tiny Tapeout arithmetic example has been replaced by the first Hasemi RTL architecture:

- `src/project.v` — Tiny Tapeout top wrapper;
- `src/spi_slave.v` — synchronized SPI Mode-0 slave;
- `src/register_bank.v` — sensor/config/status register map;
- `src/sensor_validator.v` — valid-mask and stale-data checking;
- `src/risk_engine.v` — configurable severity and weighted risk score;
- `src/risk_fsm.v` — persistence-filtered risk state machine;
- `src/event_logger.v` — event counter, last event and IRQ latch;
- `test/test.py` — cocotb regression for SPI, risk transitions and stale fault.

## Important engineering boundary

This RTL is an engineering prototype. The threshold numbers are **not geotechnical limits** and the design does not claim to predict all landslides. Field sensor selection, units, threshold calibration, deployment procedures and warning responsibility must be validated with actual site data and qualified geotechnical/domain experts before operational use.

## Next gates

1. Pass RTL regression and lint.
2. Run Tiny Tapeout synthesis/GDS CI and confirm the design physically fits the 3×2 allocation.
3. Add corner-case verification for SPI, threshold configuration, sensor faults and state hysteresis.
4. Define the external sensor/MCU board and the exact measurement units/scaling.
5. Calibrate thresholds/weights on representative field data before any field warning trial.
