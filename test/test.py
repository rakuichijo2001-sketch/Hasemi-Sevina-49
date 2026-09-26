# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


def crc8(data):
    c = 0
    for b in data:
        c ^= b
        for _ in range(8):
            c = ((c << 1) ^ 0x07) & 0xFF if (c & 0x80) else (c << 1) & 0xFF
    return c


async def set_spi_lines(dut, cs=None, sck=None, mosi=None):
    v = int(dut.uio_in.value)
    if cs is not None:
        v = (v & ~0x01) | ((cs & 1) << 0)
    if mosi is not None:
        v = (v & ~0x02) | ((mosi & 1) << 1)
    if sck is not None:
        v = (v & ~0x08) | ((sck & 1) << 3)
    dut.uio_in.value = v


async def spi_transfer(dut, tx_bytes):
    rx = []
    await set_spi_lines(dut, cs=1, sck=0, mosi=0)
    await ClockCycles(dut.clk, 4)
    await set_spi_lines(dut, cs=0)
    await ClockCycles(dut.clk, 4)

    for txb in tx_bytes:
        rxb = 0
        for bit in range(7, -1, -1):
            await set_spi_lines(dut, mosi=(txb >> bit) & 1, sck=0)
            await ClockCycles(dut.clk, 4)
            await set_spi_lines(dut, sck=1)
            await ClockCycles(dut.clk, 4)
            rxb = (rxb << 1) | (int(dut.uio_out.value) >> 2 & 1)
            await set_spi_lines(dut, sck=0)
            await ClockCycles(dut.clk, 4)
        rx.append(rxb)

    await set_spi_lines(dut, cs=1, sck=0, mosi=0)
    await ClockCycles(dut.clk, 6)
    return rx


async def reg_write(dut, addr, value, bad_crc=False):
    cmd = addr & 0x7F
    hi = (value >> 8) & 0xFF
    lo = value & 0xFF
    c = crc8([cmd, hi, lo])
    if bad_crc:
        c ^= 0x5A
    await spi_transfer(dut, [cmd, hi, lo, c])


async def reg_read(dut, addr):
    cmd = 0x80 | (addr & 0x7F)
    rx = await spi_transfer(dut, [cmd, 0, 0, 0])
    value = (rx[1] << 8) | rx[2]
    assert rx[3] == crc8([cmd, rx[1], rx[2]]), f"read CRC mismatch addr=0x{addr:02x} rx={rx}"
    return value


async def configure(dut):
    cfg = {
        0x20: 10, 0x21: 20,
        0x22: 15, 0x23: 30,
        0x24: 100, 0x25: 200,
        0x26: 5, 0x27: 10,
        0x28: 3, 0x29: 6,
        0x2A: 8, 0x2B: 16,
        # weights: rr=1, ra=1, water=2, move=3, rate=3
        0x2C: (1 << 0) | (1 << 3) | (2 << 6) | (3 << 9) | (3 << 12),
        0x2D: 2,
        0x2E: 2,
        0x2F: 3,
        0x30: 0x1F,
        0x31: 1000, 0x32: 1000, 0x33: 1000, 0x34: 1000, 0x35: 1000,
    }
    for a, v in cfg.items():
        await reg_write(dut, a, v)
    await reg_write(dut, 0x36, 0xC0DE)
    assert await reg_read(dut, 0x07) == 1


async def send_sample(dut, seq, rr, ra, water, move, rate, valid=0x1F):
    for a, v in [
        (0x10, rr), (0x11, ra), (0x12, water), (0x13, move), (0x14, rate),
        (0x15, seq), (0x16, valid),
    ]:
        await reg_write(dut, a, v)
    await reg_write(dut, 0x17, 0xA55A)
    await ClockCycles(dut.clk, 12)


def state_from_uo(dut):
    return int(dut.uo_out.value) & 0x3


@cocotb.test()
async def test_hasemi_v1(dut):
    cocotb.start_soon(Clock(dut.clk, 1, unit="us").start())
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x01  # CS_N high, SCK low
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # Fail-safe reset state: DATA_FAULT, invalid result.
    assert state_from_uo(dut) == 3
    assert (int(dut.uo_out.value) >> 2) & 1 == 0
    assert (int(dut.uo_out.value) >> 3) & 1 == 1
    assert await reg_read(dut, 0x7F) == 0x4849

    await configure(dut)

    # First valid baseline sample recovers to NORMAL.
    await send_sample(dut, 1, 0, 0, 0, 0, 0)
    assert state_from_uo(dut) == 0
    assert (int(dut.uo_out.value) >> 2) & 1 == 1

    # Persistence=2: one elevated sample is not enough to change feature levels.
    await send_sample(dut, 2, 12, 0, 120, 6, 4)
    assert state_from_uo(dut) == 0

    # Second consecutive elevated sample yields CHECK (score 9).
    await send_sample(dut, 3, 12, 0, 120, 6, 4)
    assert state_from_uo(dut) == 1
    assert await reg_read(dut, 0x06) == 9

    # Movement/rate severe must persist twice, then force HIGH.
    await send_sample(dut, 4, 12, 0, 120, 12, 7)
    assert state_from_uo(dut) == 1
    await send_sample(dut, 5, 12, 0, 120, 12, 7)
    assert state_from_uo(dut) == 2

    # Missing required sensor makes the committed dataset invalid immediately.
    await send_sample(dut, 6, 12, 0, 120, 12, 7, valid=0x0F)
    assert state_from_uo(dut) == 3
    assert (await reg_read(dut, 0x02)) & 0x02

    # Invalid sample did not advance sequence. Re-submit seq=6 valid, then seq=7.
    await send_sample(dut, 6, 0, 0, 0, 0, 0)
    assert state_from_uo(dut) == 2  # feature persistence still holds old high level for one sample
    await send_sample(dut, 7, 0, 0, 0, 0, 0)
    assert state_from_uo(dut) == 0

    # Sequence gap is rejected.
    await send_sample(dut, 9, 0, 0, 0, 0, 0)
    assert state_from_uo(dut) == 3
    assert (await reg_read(dut, 0x02)) & 0x10

    # Re-use expected seq=8 to recover.
    await send_sample(dut, 8, 0, 0, 0, 0, 0)
    assert state_from_uo(dut) == 0

    # Corrupt SPI transaction: register must not update, error counter increments.
    before = await reg_read(dut, 0x04)
    old_rr = await reg_read(dut, 0x10)
    await reg_write(dut, 0x10, 999, bad_crc=True)
    assert await reg_read(dut, 0x10) == old_rr
    assert await reg_read(dut, 0x04) == before + 1

    # Stale timeout = 3 compressed seconds (CLK_HZ=1000 in RTL TB).
    await ClockCycles(dut.clk, 3100)
    assert state_from_uo(dut) == 3
    assert (await reg_read(dut, 0x02)) & 0x20

    # A fresh valid sample clears stale state and produces a valid result again.
    await send_sample(dut, 9, 0, 0, 0, 0, 0)
    assert state_from_uo(dut) == 0
    assert (int(dut.uo_out.value) >> 2) & 1 == 1
