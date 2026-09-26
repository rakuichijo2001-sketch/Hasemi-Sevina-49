import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

SPI_HALF_PERIOD_NS = 500  # 1 MHz SPI with a 10 MHz system clock


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
