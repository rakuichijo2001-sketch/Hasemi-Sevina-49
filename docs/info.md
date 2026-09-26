## How it works

Hasemi Sevina 49 is a digital ASIC prototype for processing already-digitized field sensor data associated with slope-condition monitoring. Sensors, analog front ends/ADCs, power, long-range communications, logging, and field alarm equipment are outside this ASIC.

The field controller writes a complete sample through an SPI Mode 0 register interface. The proposed sample contains recent rainfall, antecedent rainfall, a soil-water or pore-pressure indicator, movement/tilt/displacement, movement rate, a sequence number, and a validity mask. A CRC-8 protects each SPI write. Samples are first written to staging registers and are processed only after a valid `SAMPLE_COMMIT` write, avoiding classification of partial data.

The ASIC validates configuration, required channels, optional range limits, and sample sequence continuity. Five feature blocks apply configurable low/high thresholds, hysteresis, and persistence. A weighted score plus a severe-motion override maps the accepted data to four externally visible states:

- `00` NORMAL
- `01` CHECK / NEED_INSPECTION
- `10` HIGH_RISK
- `11` DATA_FAULT

Threshold values and weights are intentionally not treated as validated geotechnical values in silicon. They must be configured from site-specific engineering data. The chip is a condition-classification prototype and is not described as a device that can predict a landslide with certainty or replace geotechnical assessment.

The design uses the Tiny Tapeout `clk` input as its only functional clock domain. The intended clock is 10 MHz. SPI inputs are synchronized into this clock domain. A one-second internal age counter marks accepted data stale after the configured timeout.

### SPI pin assignment

| Tiny Tapeout pin | Function |
| --- | --- |
| `uio[0]` | SPI `CS_N` |
| `uio[1]` | SPI `MOSI` |
| `uio[2]` | SPI `MISO` |
| `uio[3]` | SPI `SCK` |
| `uio[7:4]` | reserved inputs |

SPI mode is Mode 0, MSB first. A write transaction is four bytes: command/address, data high, data low, CRC-8. CRC polynomial is `0x07`, initial value `0x00`. Bit 7 of the command is 0 for write and 1 for read; bits 6:0 contain the register address. A read transaction is also four bytes; response data appears in bytes 1 and 2 and response CRC in byte 3.

### Register map

| Address | Name | Access |
| --- | --- | --- |
| `0x00` | STATUS | R |
| `0x01` | REASON | R |
| `0x02` | FAULT_CODE | R |
| `0x03` | LATEST_SEQ | R |
| `0x04` | CRC_ERROR_COUNT | R |
| `0x06` | SCORE | R |
| `0x07` | CONFIG_VALID | R |
| `0x10..0x14` | staged sensor values | R/W |
| `0x15` | staged sequence | R/W |
| `0x16` | staged valid mask | R/W |
| `0x17` | SAMPLE_COMMIT (`0xA55A`) | W |
| `0x20..0x29` | feature thresholds | R/W |
| `0x2A` | SCORE_CHECK | R/W |
| `0x2B` | SCORE_HIGH | R/W |
| `0x2C` | packed 3-bit feature weights | R/W |
| `0x2D` | hysteresis magnitude | R/W |
| `0x2E` | persistence sample count | R/W |
| `0x2F` | stale timeout in seconds | R/W |
| `0x30` | required sensor mask | R/W |
| `0x31..0x35` | optional maximum range checks; 0 disables that check | R/W |
| `0x36` | CONFIG_COMMIT (`0xC0DE`) | W |
| `0x7F` | design ID (`0x4849`) | R |

Writing a configuration register invalidates the active configuration until a valid `CONFIG_COMMIT` is received. Structural checks require ordered thresholds, `SCORE_CHECK < SCORE_HIGH`, nonzero persistence, nonzero stale timeout, and a nonzero required-sensor mask. These checks only confirm internal consistency; they do not validate the engineering suitability of the chosen values.

Fault-code bits are: bit 0 invalid configuration, bit 1 missing required sensor, bit 2 configured range violation, bit 3 duplicate sequence, bit 4 sequence gap, bit 5 stale accepted data, and bit 6 most recent SPI write CRC error.

## How to test

The repository uses cocotb and Icarus Verilog for RTL simulation. From the `test` directory run:

```sh
make clean
make
```

The RTL testbench compresses the one-second timebase by overriding the top-level `CLK_HZ` parameter to 1000. This override is used only for RTL simulation; synthesis uses the default 10 MHz value. The test checks fail-safe reset, SPI read/write and CRC, configuration commit, normal/check/high transitions, persistence, missing-channel faults, sequence-gap rejection, recovery with the expected sequence, corrupted SPI writes, and stale-data behavior.

GitHub Actions also runs the Tiny Tapeout SKY26d GDS flow. A successful RTL test alone is not evidence that the design is ready for fabrication. GDS build, precheck, gate-level test, timing/area results, and final submission checks must be reviewed separately.

## External hardware

Expected external hardware includes field sensors and their required analog front ends/ADCs, an MCU or data logger that converts measurements to the configured digital representation, regulated power, and any long-range communications or alarm equipment. Candidate measurements include rainfall, soil-water/pore-pressure or moisture information, and tilt/displacement. Exact sensors, units, scaling, thresholds, sample interval, and field alarm procedure remain site-specific items to validate with real data and geotechnical review.
