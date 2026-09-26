# Hasemi-Sevina-49 verification

The cocotb regression exercises the real Hasemi RTL rather than the Tiny Tapeout arithmetic template.

Coverage in `test.py`:

- SPI Mode-0 register read/write at 1 MHz with a 10 MHz system clock.
- 16-bit sensor sample loading and explicit sample commit.
- Configurable watch/critical thresholds and per-sensor weights.
- Persistence filtering before risk-state transitions.
- NORMAL -> WATCH -> CRITICAL behavior.
- IRQ generation/clear.
- Stale-sample fault using the external 1 Hz tick.

Run from `test/` in a Linux environment with Icarus Verilog and cocotb:

```sh
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
make
```
