/*
 * Test-only RV32E firmware for Hasemi-Sevina-49 v0.2.
 * It is stored in external simulated QSPI flash, never synthesized on chip.
 * SPDX-License-Identifier: Apache-2.0
 */

    .section .text
    .globl _start
_start:
    lui   x5, 0x08001         /* Hasemi MMIO base 0x08001000 */

    addi  x6, x0, 100
    sb    x6, 0x10(x5)        /* RAIN_WATCH_L */
    sb    x0, 0x11(x5)
    addi  x6, x0, 200
    sb    x6, 0x18(x5)        /* RAIN_CRIT_L */
    sb    x0, 0x19(x5)

    addi  x6, x0, 2
    sb    x6, 0x20(x5)        /* WEIGHT_RAIN */
    sb    x0, 0x21(x5)
    sb    x0, 0x22(x5)
    sb    x0, 0x23(x5)
    sb    x6, 0x24(x5)        /* SCORE_WATCH */
    addi  x6, x0, 3
    sb    x6, 0x25(x5)        /* SCORE_WARNING */
    addi  x6, x0, 4
    sb    x6, 0x26(x5)        /* SCORE_CRITICAL */
    addi  x6, x0, 1
    sb    x6, 0x27(x5)        /* PERSIST_UP */
    sb    x6, 0x28(x5)        /* PERSIST_DOWN */
    addi  x6, x0, 15
    sb    x6, 0x29(x5)        /* REQUIRED_MASK */
    sb    x6, 0x0c(x5)        /* VALID_MASK */

    lbu   x7, 0x00(x5)        /* read CHIP_ID */
    sb    x7, 0x08(x5)        /* copy to TILT_L for observation */

    addi  x6, x0, 0x5a
    sb    x6, 0(x3)           /* gp is hardwired to PSRAM A + 0x400 */
    lbu   x7, 0(x3)
    sb    x7, 0x09(x5)        /* PSRAM round-trip marker in TILT_H */

    addi  x6, x0, 250
    sb    x6, 0x04(x5)        /* RAIN_L */
    sb    x0, 0x05(x5)
    sb    x0, 0x06(x5)
    sb    x0, 0x07(x5)
    sb    x0, 0x0a(x5)
    sb    x0, 0x0b(x5)
    addi  x6, x0, 0xa5
    sb    x6, 0x0d(x5)        /* COMMIT */

    lbu   x7, 0x31(x5)        /* CPU reads RISK_LEVEL */
    sb    x7, 0x0a(x5)        /* copy to DISP_L */
    lbu   x7, 0x30(x5)        /* CPU reads RISK_SCORE */
    sb    x7, 0x0b(x5)        /* copy to DISP_H */
    lbu   x7, 0x35(x5)        /* CPU reads EVENT_COUNT */
    sb    x7, 0x06(x5)        /* copy to WATER_L */

1:  jal   x0, 1b

