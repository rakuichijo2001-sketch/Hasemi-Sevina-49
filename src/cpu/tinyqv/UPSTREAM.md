# TinyQV upstream provenance

These Verilog files are an intentionally minimal, unmodified import from the
TinyQV core used by the TT06 TinyQV SoC.

- TT06 integration repository:
  `https://github.com/MichaelBell/tt06-tinyQV`
- TT06 commit inspected:
  `981d02792d4c2545e995b57b89df889cae925cd5`
- Exact `src/tinyQV` gitlink/core commit imported:
  `dfbd5e3882442c07e4627bfb5f627ba7bff00baf`
- Core repository: `https://github.com/MichaelBell/tinyQV`
- License: Apache License 2.0 (upstream root `LICENSE`)
- Upstream author/copyright: Michael Bell; file headers are preserved verbatim.

Imported dependency closure:

| File | SHA-256 |
|---|---|
| `alu.v` | `9c75d83117128e376d61b55639459af61c4db39bd5d7cee35948809679bea806` |
| `core.v` | `19f590a37e856e8804550a27670d3ae4f35b8dab04eb0f5bccb96b4fbb02a90b` |
| `counter.v` | `6d5c89c1b7c2541cc49ece4e8fde1ca7f04b1ceda44d757f7ce914d61c4c8209` |
| `cpu.v` | `a39f4810066f214c8ddf2af982c256b2ebee99c5a8eb22f0bd1b118428506aa0` |
| `decode.v` | `3924da888c32ef2a2962748c79be0d50cf3dd9c333239ce16b3f08e1317a6d14` |
| `mem_ctrl.v` | `0ceadd8555665c11da93bf40d86d09c8b032760c6b44446967e409af90bcfcc8` |
| `qspi_ctrl.v` | `37344f617465a8f76ba3dacecce04c7cf0a790e2d68df132d25c90b0a240967f` |
| `register.v` | `1676425140973508276174753bd667ba344fab2204e14f356220cde5a7344a1c` |
| `tinyqv.v` | `a1a2234ca7da50ad5f1590a4c2de2d77ff6195df6381a73eef5def72d90ac95f` |

Files deliberately excluded include the upstream TT wrapper, UART, generic SPI,
PWM, FPGA wrappers, board software, and all demo-specific logic. Local Hasemi
adaptation belongs outside this directory so `sha256sum` can continue proving
the imported files are byte-identical to the pinned upstream commit.

