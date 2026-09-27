## How it works

Hasemi-Sevina-49 is a digital edge processor for a slope-monitoring field node. An external MCU or ADC front end converts sensor measurements to unsigned 16-bit values and writes them to the ASIC through SPI.

Four v0.1 sensor channels are implemented: rainfall, water-related condition, tilt and displacement. Each channel has configurable WATCH and CRITICAL thresholds. The hardware converts each measurement to severity 0/1/2, multiplies the severity by a small programmable weight and sums the contributions into an 8-bit risk score.

Three programmable score thresholds map that score to `WATCH`, `WARNING` or `CRITICAL`. A persistence filter requires a configurable number of consecutive committed samples before the state changes, which reduces chatter around thresholds.

The validator checks the required sensor-valid mask, an optional stale-sample timeout based on `TICK_1HZ`, an external fault input and configuration ordering. Fault is reported independently from the risk state.

The event logger records state/fault events and latches `IRQ` until software clears it.

## How to test

Use a 10 MHz clock on the standard Tiny Tapeout `clk` input. Use SPI Mode 0 on `ui[0:2]` and keep SPI at or below 2 MHz for this first revision.

1. Read `CHIP_ID` register `0x00`; it must return `0x49`.
2. Configure sensor thresholds, weights, score thresholds and persistence counts.
3. Write all four 16-bit sensor values and `VALID_MASK`.
4. Write `0xA5` to `COMMIT` (`0x0D`).
5. Read `RISK_SCORE`, `RISK_LEVEL`, `REASON_CODE`, and observe dedicated WATCH/WARNING/CRITICAL/FAULT/IRQ outputs.
6. For stale-data testing, configure `TIMEOUT_S`, stop committing samples and provide rising pulses on `TICK_1HZ`.

The cocotb regression in `test/test.py` automates these checks.

## External hardware

Expected external hardware for a field prototype:

- MCU/gateway with SPI master;
- sensor front ends/ADCs for the selected rainfall, water, tilt and displacement sensors;
- optional 1 Hz timing signal;
- local alarm/relay driver if physical actuation is required;
- independent communication module or gateway for LoRaWAN, cellular or satellite connectivity.

The ASIC itself contains no analog sensor interface, radio, GNSS or cloud stack.
