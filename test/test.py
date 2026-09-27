import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

SPI_HALF_PERIOD_NS = 500  # conservative legacy regression timing
SPI_2MHZ_HALF_PERIOD_NS = 250


async def spi_transfer(dut, command, data=0):
    dut.ui_in.value = int(dut.ui_in.value) | 0x04
    await Timer(SPI_HALF_PERIOD_NS, unit="ns")

    dut.ui_in.value = int(dut.ui_in.value) & ~0x04
    await Timer(SPI_HALF_PERIOD_NS, unit="ns")

    rx = 0
    word = ((command & 0xFF) << 8) | (data & 0xFF)

    for bit_index in range(15, -1, -1):
        bit = (word >> bit_index) & 1
        v = int(dut.ui_in.value)
        v = (v & ~0x02) | (bit << 1)
        v &= ~0x01
        dut.ui_in.value = v
        await Timer(SPI_HALF_PERIOD_NS, unit="ns")

        dut.ui_in.value = int(dut.ui_in.value) | 0x01
        await Timer(SPI_HALF_PERIOD_NS // 2, unit="ns")
        rx = ((rx << 1) | (int(dut.uo_out.value) & 0x1)) & 0xFFFF
        await Timer(SPI_HALF_PERIOD_NS // 2, unit="ns")

        dut.ui_in.value = int(dut.ui_in.value) & ~0x01
        await Timer(SPI_HALF_PERIOD_NS, unit="ns")

    dut.ui_in.value = int(dut.ui_in.value) | 0x04
    await Timer(SPI_HALF_PERIOD_NS * 2, unit="ns")
    return rx & 0xFF


async def spi_write(dut, addr, value):
    await spi_transfer(dut, 0x80 | (addr & 0x7F), value)


async def spi_read(dut, addr):
    return await spi_transfer(dut, addr & 0x7F, 0x00)


async def write_u16(dut, low_addr, value):
    await spi_write(dut, low_addr, value & 0xFF)
    await spi_write(dut, low_addr + 1, (value >> 8) & 0xFF)


async def commit_sample(dut):
    await spi_write(dut, 0x0D, 0xA5)
    await ClockCycles(dut.clk, 5)


@cocotb.test()
async def test_hasemi_sevina_49_core(dut):
    cocotb.start_soon(Clock(dut.clk, 100, unit="ns").start())

    dut.ena.value = 1
    dut.ui_in.value = 0x04
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    assert await spi_read(dut, 0x00) == 0x49
    assert await spi_read(dut, 0x01) == 0x10

    for low_addr in (0x10, 0x12, 0x14, 0x16):
        await write_u16(dut, low_addr, 100)
    for low_addr in (0x18, 0x1A, 0x1C, 0x1E):
        await write_u16(dut, low_addr, 200)

    for addr in (0x20, 0x21, 0x22, 0x23):
        await spi_write(dut, addr, 2)

    await spi_write(dut, 0x24, 2)
    await spi_write(dut, 0x25, 6)
    await spi_write(dut, 0x26, 12)
    await spi_write(dut, 0x27, 2)
    await spi_write(dut, 0x28, 2)
    await spi_write(dut, 0x29, 0x0F)
    await spi_write(dut, 0x2A, 3)

    await spi_write(dut, 0x0C, 0x0F)
    await spi_write(dut, 0x02, 0x03)

    for addr in (0x04, 0x06, 0x08, 0x0A):
        await write_u16(dut, addr, 50)
    await commit_sample(dut)
    assert ((await spi_read(dut, 0x31)) & 0x03) == 0
    assert ((int(dut.uo_out.value) >> 3) & 1) == 0

    await write_u16(dut, 0x04, 150)
    await commit_sample(dut)
    assert ((await spi_read(dut, 0x31)) & 0x03) == 0
    await commit_sample(dut)
    assert ((await spi_read(dut, 0x31)) & 0x03) == 1
    assert ((int(dut.uo_out.value) >> 4) & 1) == 1

    for addr in (0x04, 0x06, 0x08, 0x0A):
        await write_u16(dut, addr, 250)
    await commit_sample(dut)
    await commit_sample(dut)

    assert await spi_read(dut, 0x30) == 16
    assert ((await spi_read(dut, 0x31)) & 0x03) == 3
    assert ((int(dut.uo_out.value) >> 2) & 1) == 1
    assert ((int(dut.uo_out.value) >> 7) & 1) == 1

    await spi_write(dut, 0x02, 0x03)
    await ClockCycles(dut.clk, 5)
    assert ((int(dut.uo_out.value) >> 7) & 1) == 0

    for _ in range(3):
        dut.ui_in.value = int(dut.ui_in.value) | 0x08
        await ClockCycles(dut.clk, 4)
        dut.ui_in.value = int(dut.ui_in.value) & ~0x08
        await ClockCycles(dut.clk, 4)

    assert ((int(dut.uo_out.value) >> 3) & 1) == 1
    status = await spi_read(dut, 0x03)
    assert ((status >> 2) & 1) == 1



async def start_and_reset(dut):
    cocotb.start_soon(Clock(dut.clk, 100, unit="ns").start())
    dut.ena.value = 1
    dut.ui_in.value = 0x04
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)


async def spi_transfer_timed(dut, command, data=0, half_period_ns=SPI_2MHZ_HALF_PERIOD_NS, phase_offset_ns=0):
    if phase_offset_ns:
        await Timer(phase_offset_ns, unit="ns")

    # SPI mode 0: idle low, sample on rising edge, change/advance on falling edge.
    v = int(dut.ui_in.value)
    v &= ~0x01
    v |= 0x04
    dut.ui_in.value = v
    await Timer(half_period_ns, unit="ns")

    dut.ui_in.value = int(dut.ui_in.value) & ~0x04
    await Timer(half_period_ns, unit="ns")

    rx = 0
    word = ((command & 0xFF) << 8) | (data & 0xFF)

    for bit_index in range(15, -1, -1):
        bit = (word >> bit_index) & 1
        v = int(dut.ui_in.value)
        v = (v & ~0x02) | (bit << 1)
        v &= ~0x01
        dut.ui_in.value = v
        await Timer(half_period_ns, unit="ns")

        dut.ui_in.value = int(dut.ui_in.value) | 0x01
        await Timer(half_period_ns // 2, unit="ns")
        rx = ((rx << 1) | (int(dut.uo_out.value) & 0x1)) & 0xFFFF
        await Timer(half_period_ns - (half_period_ns // 2), unit="ns")

        dut.ui_in.value = int(dut.ui_in.value) & ~0x01

    await Timer(half_period_ns, unit="ns")
    dut.ui_in.value = int(dut.ui_in.value) | 0x04
    await Timer(half_period_ns, unit="ns")
    return rx & 0xFF


async def spi_write_timed(dut, addr, value, phase_offset_ns=0):
    await spi_transfer_timed(
        dut,
        0x80 | (addr & 0x7F),
        value,
        phase_offset_ns=phase_offset_ns,
    )


async def spi_read_timed(dut, addr, phase_offset_ns=0):
    return await spi_transfer_timed(
        dut,
        addr & 0x7F,
        0x00,
        phase_offset_ns=phase_offset_ns,
    )


async def configure_standard_fast_transition(dut, timeout_s=0):
    for low_addr in (0x10, 0x12, 0x14, 0x16):
        await write_u16(dut, low_addr, 100)
    for low_addr in (0x18, 0x1A, 0x1C, 0x1E):
        await write_u16(dut, low_addr, 200)

    for addr in (0x20, 0x21, 0x22, 0x23):
        await spi_write(dut, addr, 2)

    await spi_write(dut, 0x24, 2)
    await spi_write(dut, 0x25, 6)
    await spi_write(dut, 0x26, 12)
    await spi_write(dut, 0x27, 1)
    await spi_write(dut, 0x28, 1)
    await spi_write(dut, 0x29, 0x0F)
    await spi_write(dut, 0x2A, timeout_s)
    await spi_write(dut, 0x0C, 0x0F)
    await spi_write(dut, 0x02, 0x01)


async def pulse_tick_1hz(dut):
    dut.ui_in.value = int(dut.ui_in.value) | 0x08
    await ClockCycles(dut.clk, 4)
    dut.ui_in.value = int(dut.ui_in.value) & ~0x08
    await ClockCycles(dut.clk, 4)


@cocotb.test()
async def test_spi_exact_2mhz_with_phase_offsets(dut):
    await start_and_reset(dut)

    for index, phase_ns in enumerate((0, 25, 50, 75)):
        assert await spi_read_timed(dut, 0x00, phase_offset_ns=phase_ns) == 0x49

        value = 0x31 + index
        await spi_write_timed(dut, 0x04, value, phase_offset_ns=phase_ns)
        assert await spi_read_timed(dut, 0x04, phase_offset_ns=phase_ns) == value


@cocotb.test()
async def test_threshold_boundaries_and_invalid_config(dut):
    await start_and_reset(dut)

    for low_addr in (0x10, 0x12, 0x14, 0x16):
        await write_u16(dut, low_addr, 100)
    for low_addr in (0x18, 0x1A, 0x1C, 0x1E):
        await write_u16(dut, low_addr, 200)

    await spi_write(dut, 0x20, 2)
    for addr in (0x21, 0x22, 0x23):
        await spi_write(dut, addr, 0)

    await spi_write(dut, 0x24, 2)
    await spi_write(dut, 0x25, 3)
    await spi_write(dut, 0x26, 4)
    await spi_write(dut, 0x27, 1)
    await spi_write(dut, 0x28, 1)
    await spi_write(dut, 0x29, 0x0F)
    await spi_write(dut, 0x2A, 0)
    await spi_write(dut, 0x0C, 0x0F)
    await spi_write(dut, 0x02, 0x01)

    for addr in (0x06, 0x08, 0x0A):
        await write_u16(dut, addr, 0)

    cases = (
        (99, 0, 0, 0),
        (100, 1, 2, 1),
        (101, 1, 2, 1),
        (199, 1, 2, 1),
        (200, 2, 4, 3),
        (201, 2, 4, 3),
    )

    for value, expected_severity, expected_score, expected_level in cases:
        await write_u16(dut, 0x04, value)
        await commit_sample(dut)

        severity = await spi_read(dut, 0x36)
        assert (severity & 0x03) == expected_severity
        assert await spi_read(dut, 0x30) == expected_score
        assert ((await spi_read(dut, 0x31)) & 0x03) == expected_level

    await write_u16(dut, 0x10, 201)
    await ClockCycles(dut.clk, 5)
    assert ((int(dut.uo_out.value) >> 3) & 1) == 1
    assert (((await spi_read(dut, 0x03)) >> 2) & 1) == 1

    await write_u16(dut, 0x10, 100)
    await ClockCycles(dut.clk, 5)
    assert ((int(dut.uo_out.value) >> 3) & 1) == 0


@cocotb.test()
async def test_reset_external_fault_and_stale_recovery(dut):
    await start_and_reset(dut)

    assert await spi_read(dut, 0x00) == 0x49
    await configure_standard_fast_transition(dut, timeout_s=2)

    for addr in (0x04, 0x06, 0x08, 0x0A):
        await write_u16(dut, addr, 50)
    await commit_sample(dut)

    dut.ui_in.value = int(dut.ui_in.value) | 0x10
    await ClockCycles(dut.clk, 5)
    assert ((int(dut.uo_out.value) >> 3) & 1) == 1

    dut.ui_in.value = int(dut.ui_in.value) & ~0x10
    await ClockCycles(dut.clk, 5)
    assert ((int(dut.uo_out.value) >> 3) & 1) == 0

    await pulse_tick_1hz(dut)
    assert ((int(dut.uo_out.value) >> 3) & 1) == 0
    await pulse_tick_1hz(dut)
    assert ((int(dut.uo_out.value) >> 3) & 1) == 1
    assert await spi_read(dut, 0x0E) == 2

    await commit_sample(dut)
    assert await spi_read(dut, 0x0E) == 0
    assert ((int(dut.uo_out.value) >> 3) & 1) == 0

    for addr in (0x04, 0x06, 0x08, 0x0A):
        await write_u16(dut, addr, 250)
    await commit_sample(dut)
    assert ((int(dut.uo_out.value) >> 2) & 1) == 1

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    assert ((int(dut.uo_out.value) >> 2) & 1) == 0
    assert ((int(dut.uo_out.value) >> 7) & 1) == 0

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)
    assert ((await spi_read(dut, 0x31)) & 0x03) == 0
