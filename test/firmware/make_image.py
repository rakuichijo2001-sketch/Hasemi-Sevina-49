#!/usr/bin/env python3
"""Build the reviewable test-only RV32I image without a cross toolchain."""

from pathlib import Path


def check_reg(reg):
    assert 0 <= reg < 16, "TinyQV implements RV32E registers x0-x15"


def lui(rd, imm20):
    check_reg(rd)
    assert 0 <= imm20 < (1 << 20)
    return (imm20 << 12) | (rd << 7) | 0x37


def addi(rd, rs1, imm):
    check_reg(rd)
    check_reg(rs1)
    assert -2048 <= imm < 2048
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (rd << 7) | 0x13


def lbu(rd, rs1, imm):
    check_reg(rd)
    check_reg(rs1)
    assert -2048 <= imm < 2048
    return (
        ((imm & 0xFFF) << 20)
        | (rs1 << 15)
        | (0b100 << 12)
        | (rd << 7)
        | 0x03
    )


def sb(rs2, rs1, imm):
    check_reg(rs2)
    check_reg(rs1)
    assert -2048 <= imm < 2048
    encoded = imm & 0xFFF
    return (
        (((encoded >> 5) & 0x7F) << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | ((encoded & 0x1F) << 7)
        | 0x23
    )


def jal_zero():
    return 0x0000006F


PROGRAM = [
    lui(5, 0x08001),
    addi(6, 0, 100),
    sb(6, 5, 0x10),
    sb(0, 5, 0x11),
    addi(6, 0, 200),
    sb(6, 5, 0x18),
    sb(0, 5, 0x19),
    addi(6, 0, 2),
    sb(6, 5, 0x20),
    sb(0, 5, 0x21),
    sb(0, 5, 0x22),
    sb(0, 5, 0x23),
    sb(6, 5, 0x24),
    addi(6, 0, 3),
    sb(6, 5, 0x25),
    addi(6, 0, 4),
    sb(6, 5, 0x26),
    addi(6, 0, 1),
    sb(6, 5, 0x27),
    sb(6, 5, 0x28),
    addi(6, 0, 15),
    sb(6, 5, 0x29),
    sb(6, 5, 0x0C),
    lbu(7, 5, 0x00),
    sb(7, 5, 0x08),
    addi(6, 0, 0x5A),
    sb(6, 3, 0x00),
    lbu(7, 3, 0x00),
    sb(7, 5, 0x09),
    addi(6, 0, 250),
    sb(6, 5, 0x04),
    sb(0, 5, 0x05),
    sb(0, 5, 0x06),
    sb(0, 5, 0x07),
    sb(0, 5, 0x0A),
    sb(0, 5, 0x0B),
    addi(6, 0, 0xA5),
    sb(6, 5, 0x0D),
    lbu(7, 5, 0x31),
    sb(7, 5, 0x0A),
    lbu(7, 5, 0x30),
    sb(7, 5, 0x0B),
    lbu(7, 5, 0x35),
    sb(7, 5, 0x06),
    jal_zero(),
]


def main():
    data = b"".join(word.to_bytes(4, "little") for word in PROGRAM)
    out = Path(__file__).with_name("hasemi_v02.hex")
    out.write_text("\n".join(f"{byte:02x}" for byte in data) + "\n")
    print(f"wrote {len(data)} bytes ({len(PROGRAM)} instructions) to {out}")


if __name__ == "__main__":
    main()

