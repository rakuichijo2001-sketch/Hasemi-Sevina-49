# Repository engineering rules

Before changing RTL, tests, pin maps, clocks, resets, or source lists, read
`docs/rtl-pd-development-rules.md` and the relevant architecture/verification
documents under `docs/`.

Required order for every non-trivial RTL change:

1. Confirm branch, commit, and working-tree state; preserve unrelated files.
2. State the requirement, golden invariants, verification matrix, PPA hypothesis,
   acceptance criteria, risks, and rollback point before editing.
3. Run and record the existing golden regression before and after the change.
4. Add or update tests for the new behavior; do not change expected results just
   to make tests pass.
5. Run compile/lint and inspect synthesis counts, inferred memories, warnings,
   dead logic, fanout and mux structure.
6. Run the target Tiny Tapeout SKY26d 3x2 physical flow for material changes;
   review congestion, timing, DRC/LVS/antenna, precheck and GLS before declaring
   completion.
7. Record exact commit SHA and evidence. Never infer physical fit from RTL,
   synthesis alone, another commit's artifacts, or an intermediate route log.

Preserve the v0.1 risk-accelerator semantics and TinyQV upstream source hashes.
Do not add false paths, multicycle exceptions, test-only memories to synthesis,
or unrelated peripherals to make a flow pass. Keep failing evidence visible.
Use small commits with messages that identify the technical change.
