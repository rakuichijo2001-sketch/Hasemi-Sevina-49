# Hasemi-Sevina-49 — RTL v0.1 requirements baseline

## 1. Role in the system

Hasemi-Sevina-49 is the deterministic **Layer-1 edge risk processor** in a larger monitoring architecture. It sits after sensor digitization and before the external MCU/gateway. Cloud/IOC systems may configure and monitor it through that MCU, but local risk/fault outputs remain available without a cloud round trip.

## 2. Fixed v0.1 architectural decisions

- Digital-only ASIC for Tiny Tapeout SKY26d / SKY130.
- Target reservation: 3×2 tiles; physical fit still has to be proven by synthesis/place-and-route.
- Standard system clock target: 10 MHz.
- External MCU is retained for sensor protocols, ADCs, communications, OTA and cloud connectivity.
- MCU-to-ASIC control interface: SPI Mode 0, initial target <=2 MHz.
- Four unsigned 16-bit logical sensor channels: rain, water-related condition, tilt and displacement.
- Sensor values are engineering-code values; unit scaling is owned by the external MCU/system specification.
- Separate risk state and fault indication.

## 3. Risk processing

Each sensor has programmable WATCH and CRITICAL thresholds. Hardware severity is:

- `0`: value below WATCH threshold;
- `1`: value at/above WATCH but below CRITICAL;
- `2`: value at/above CRITICAL.

Each severity is multiplied by a programmable 4-bit weight. The four contributions are summed to an 8-bit risk score. Programmable score thresholds produce candidate levels `NORMAL`, `WATCH`, `WARNING`, `CRITICAL`.

State changes require programmable consecutive-sample persistence for escalation and de-escalation.

The numerical thresholds and weights in verification are test vectors only; they are not field safety criteria.

## 4. Data integrity and fault handling

The chip shall expose a fault when any of the following is true:

- a bit required by `REQUIRED_MASK` is missing from `VALID_MASK`;
- committed data becomes stale relative to the optional 1 Hz timeout;
- `EXT_FAULT` is asserted;
- WATCH/CRITICAL threshold ordering or score-threshold ordering is invalid.

A fault is reported independently of the risk FSM so that invalid data cannot silently appear as a valid low-risk result.

## 5. Event handling

The chip records event count and last-event state/reason/score. `IRQ` latches when a risk-state transition or a new fault occurs and remains asserted until software clears it.

## 6. Items intentionally outside v0.1 ASIC scope

- analog sensor interfaces/ADCs;
- LoRaWAN/4G/5G/Starlink radios;
- GNSS;
- cloud, GIS, ERP, Digital Twin and IOC software;
- general-purpose CPU/MCU and firmware boot stack;
- direct high-power actuator drive;
- geotechnical model calibration and formal safety certification.

## 7. Open engineering decisions before field trial

- exact deployment site and sensing modalities;
- physical units and fixed-point/scaling convention for each 16-bit channel;
- qualified sensor ranges, sampling interval and calibration process;
- evidence-based field thresholds and weights;
- local alarm/actuator interlock policy;
- EMC, power, packaging and environmental qualification outside the Tiny Tapeout demonstration chip.
