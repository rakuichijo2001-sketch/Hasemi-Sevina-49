import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from test import spi_read


async def reset_with_qspi_model(dut, latency=1):
    dut.ena.value = 1
    dut.ui_in.value = 0x04  # external Hasemi SPI idle (CS_N high)
    dut.uio_in_direct.value = 0
    dut.qspi_model_enable.value = 1
    dut.qspi_latency_cfg.value = latency

    # Match the upstream TinyQV reset contract: establish a high state, assert
    # low for multiple clocks so the memory latency code is sampled, then run.
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    assert int(dut.uio_oe.value) == 0x00
    assert int(dut.uio_out.value) == 0xC1
    # v0.1 intentionally reports missing required sensors after reset; only
    # state/IRQ outputs are required low here.
    assert (int(dut.uo_out.value) & 0x84) == 0
    await ClockCycles(dut.clk, 8)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    # Boot may already be in the command/address phase (all four SD pins are
    # outputs) or still idle (all four SD pins are inputs). Both legal values
    # keep CS/SCK output enables asserted and are fully deterministic.
    assert int(dut.uio_oe.value) in (0xC9, 0xFF)


@cocotb.test()
async def test_tinyqv_boot_psram_mmio_and_risk(dut):
    """Boot from flash and prove CPU read/write paths into Hasemi and PSRAM."""

    cocotb.start_soon(Clock(dut.clk, 100, unit="ns").start())
    await reset_with_qspi_model(dut, latency=1)

    # Exercise register-port arbitration while the CPU is fetching. Every SPI
    # read must remain correct; the CPU waits and resumes after CS_N deasserts.
    for _ in range(4):
        assert await spi_read(dut, 0x00) == 0x49

    # Poll only externally visible registers. This works for both RTL and GLS
    # and proves the CPU was not optimized away.
    for _ in range(120):
        tilt_low = await spi_read(dut, 0x08)
        tilt_high = await spi_read(dut, 0x09)
        if tilt_low == 0x49 and tilt_high == 0x5A:
            break
        await ClockCycles(dut.clk, 40)
    else:
        raise AssertionError("CPU did not complete CHIP_ID read and PSRAM round-trip")

    assert await spi_read(dut, 0x10) == 100
    assert await spi_read(dut, 0x11) == 0
    assert await spi_read(dut, 0x18) == 200
    assert await spi_read(dut, 0x19) == 0

    for _ in range(120):
        sample_seq = await spi_read(dut, 0x37)
        if sample_seq == 1:
            break
        await ClockCycles(dut.clk, 40)
    else:
        raise AssertionError("CPU did not commit the configured Hasemi sample")

    assert await spi_read(dut, 0x30) == 4
    assert (await spi_read(dut, 0x31)) & 0x03 == 3
    assert (int(dut.uo_out.value) >> 2) & 1 == 1
    assert (int(dut.uo_out.value) >> 7) & 1 == 1

    # Firmware copies CPU-read status into ordinary writable registers. This is
    # a black-box proof of the MMIO read response path.
    for _ in range(120):
        copied_level = await spi_read(dut, 0x0A)
        copied_score = await spi_read(dut, 0x0B)
        copied_events = await spi_read(dut, 0x06)
        if copied_level == 3 and copied_score == 4 and copied_events >= 1:
            break
        await ClockCycles(dut.clk, 40)
    else:
        raise AssertionError("CPU did not copy risk/event MMIO reads back to Hasemi")


@cocotb.test()
async def test_qspi_reset_during_boot_is_deterministic(dut):
    cocotb.start_soon(Clock(dut.clk, 100, unit="ns").start())
    await reset_with_qspi_model(dut, latency=1)

    await ClockCycles(dut.clk, 35)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    assert int(dut.uio_oe.value) == 0x00
    assert int(dut.uio_out.value) == 0xC1
    assert (int(dut.uo_out.value) & 0x84) == 0

    await ClockCycles(dut.clk, 8)
    dut.rst_n.value = 1

    for _ in range(140):
        if await spi_read(dut, 0x37) == 1:
            break
        await ClockCycles(dut.clk, 40)
    else:
        raise AssertionError("CPU did not recover and reboot after mid-boot reset")

    assert await spi_read(dut, 0x30) == 4
    assert (await spi_read(dut, 0x31)) & 0x03 == 3
