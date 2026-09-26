# Hasemi-Sevina-49 register map — RTL v0.1

SPI command byte is `[R/W][A6:A0]`; `R/W=1` writes and `R/W=0` reads. All registers are 8-bit. Multi-byte sensor/threshold values are little-endian (`L` then `H`).

| Addr | Name | Access | Description |
|---:|---|:---:|---|
| 0x00 | CHIP_ID | R | `0x49` |
| 0x01 | VERSION | R | `0x10` = v0.1 |
| 0x02 | CONTROL | R/W | bit0 enable; write bit1 clear IRQ; write bit2 clear events |
| 0x03 | STATUS | R | bits1:0 risk; bit2 fault; bit3 IRQ; bit4 enable |
| 0x04/05 | RAIN_L/H | R/W | 16-bit rain channel |
| 0x06/07 | WATER_L/H | R/W | 16-bit water channel |
| 0x08/09 | TILT_L/H | R/W | 16-bit tilt channel |
| 0x0A/0B | DISP_L/H | R/W | 16-bit displacement channel |
| 0x0C | VALID_MASK | R/W | bits3:0 correspond to rain/water/tilt/displacement |
| 0x0D | COMMIT | W | write `0xA5` to accept the current sensor set |
| 0x0E | SAMPLE_AGE | R | seconds since last committed sample, saturated at 255 |
| 0x0F | REASON | R | contributor bits: rain/water/tilt/displacement |
| 0x10/11 | RAIN_WATCH_L/H | R/W | 16-bit watch threshold |
| 0x12/13 | WATER_WATCH_L/H | R/W | 16-bit watch threshold |
| 0x14/15 | TILT_WATCH_L/H | R/W | 16-bit watch threshold |
| 0x16/17 | DISP_WATCH_L/H | R/W | 16-bit watch threshold |
| 0x18/19 | RAIN_CRIT_L/H | R/W | 16-bit critical threshold |
| 0x1A/1B | WATER_CRIT_L/H | R/W | 16-bit critical threshold |
| 0x1C/1D | TILT_CRIT_L/H | R/W | 16-bit critical threshold |
| 0x1E/1F | DISP_CRIT_L/H | R/W | 16-bit critical threshold |
| 0x20 | WEIGHT_RAIN | R/W | low nibble, 0..15 |
| 0x21 | WEIGHT_WATER | R/W | low nibble, 0..15 |
| 0x22 | WEIGHT_TILT | R/W | low nibble, 0..15 |
| 0x23 | WEIGHT_DISP | R/W | low nibble, 0..15 |
| 0x24 | SCORE_WATCH | R/W | risk-score watch threshold |
| 0x25 | SCORE_WARNING | R/W | risk-score warning threshold |
| 0x26 | SCORE_CRITICAL | R/W | risk-score critical threshold |
| 0x27 | PERSIST_UP | R/W | consecutive commits required for escalation; 0/1 means immediate |
| 0x28 | PERSIST_DOWN | R/W | consecutive commits required for de-escalation; 0/1 means immediate |
| 0x29 | REQUIRED_MASK | R/W | required valid sensor bits |
| 0x2A | TIMEOUT_S | R/W | stale timeout in external 1 Hz ticks; 0 disables stale timeout |
| 0x30 | RISK_SCORE | R | fused score, maximum 120 |
| 0x31 | RISK_LEVEL | R | 0 normal, 1 watch, 2 warning, 3 critical |
| 0x32 | LAST_EVENT_LEVEL | R | last logged level |
| 0x33 | LAST_EVENT_REASON | R | last contributor mask |
| 0x34 | LAST_EVENT_SCORE | R | last logged score |
| 0x35 | EVENT_COUNT | R | saturating event count |
| 0x36 | SEVERITY | R | packed 2-bit severities: `{disp, tilt, water, rain}` |
| 0x37 | SAMPLE_SEQ | R | increments on each valid `COMMIT` write |

## Dedicated pins

### Inputs

- `ui[0]`: SPI_SCLK
- `ui[1]`: SPI_MOSI
- `ui[2]`: SPI_CS_N
- `ui[3]`: TICK_1HZ
- `ui[4]`: EXT_FAULT
- `ui[7:5]`: reserved

### Outputs

- `uo[0]`: SPI_MISO
- `uo[1]`: ALERT (`WARNING | CRITICAL | SENSOR_FAULT`)
- `uo[2]`: CRITICAL
- `uo[3]`: SENSOR_FAULT
- `uo[4]`: WATCH
- `uo[5]`: WARNING
- `uo[6]`: HEARTBEAT
- `uo[7]`: IRQ
