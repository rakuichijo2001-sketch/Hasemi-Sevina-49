# RTL and physical design development rules

Status: required workflow for Hasemi v0.2 and later experiments  
Scope: `design/hasemi-v0.2-tinyqv` and later development branches  
Golden reference: v0.1 commit `44ae9879e6f25999b8569dbe8b5acdf4e2fd1a9a`

This document makes verification, synthesis and physical design part of RTL
development from the start. A feature is not considered complete when it only
compiles or passes RTL simulation.

## 1. Non-negotiable project boundaries

1. Keep v0.1 Hasemi risk processing as the golden functional reference.
   Changes to `risk_engine`, `sensor_validator`, `risk_fsm`, `event_logger`, or
   `register_bank` require a concrete requirement, a golden comparison, and an
   explicit review of all affected register/output semantics.
2. Do not change the golden branch while developing or optimizing v0.2.
3. Preserve upstream CPU sources byte-for-byte. Put local adaptation in wrapper,
   bridge, configuration or test code and record upstream provenance.
4. Do not add synthesized memories or peripherals merely to make a test easier.
   Behavioral memories belong under `test/` and must remain outside
   `info.yaml` synthesis sources.
5. Do not hide failures by changing expected values, disabling checks, adding
   unjustified false paths/multicycle paths, or weakening the design goal.
6. Keep commits small, reviewable and tied to a requirement or measured
   optimization hypothesis.

## 2. Gate 0: freeze the starting point before editing

Before every feature or optimization:

- confirm branch, commit, clean/dirty working tree, and preserved local files;
- identify the exact baseline commit and source/tool/PDK versions;
- run and archive the existing RTL regression and record each testcase;
- collect the current synthesis and physical metrics for the same source;
- record current warnings, cell/FF/mux counts, memories, critical paths,
  utilization, route congestion, DRC/LVS/antenna, and timing by corner;
- list affected RTL modules, interfaces, register behavior and constraints.

If the same-source baseline has not been hardened, label area/timing claims
`unknown`; estimates and unrelated commits are not physical baselines.

## 3. Gate 1: approve the design change on paper

Every change starts with a short change record containing:

| Field | Required content |
|---|---|
| Requirement | What behavior or measured physical problem is being addressed |
| Scope | Modules, interfaces, pins, register offsets and clock/reset domains touched |
| Functional invariants | Golden behaviors that must remain identical |
| Verification | Directed tests, regression tests, assertions and reset/error cases |
| PPA hypothesis | Expected cell/FF/mux/area/path/congestion effect and why |
| Risks | CDC, reset, arbitration, boot, pin contention, synthesis and timing risks |
| Acceptance | Numeric or pass/fail evidence required to keep the change |
| Rollback | Commit or branch that restores the previous implementation |

Do not implement a physical optimization without naming the metric it should
improve. Do not accept an optimization if its function or proof coverage drops.

## 4. Gate 2: RTL and verification before synthesis

Before a change reaches synthesis:

- compile and lint all production sources with the project flow;
- check widths, signedness, reset behavior, CDC, multiple drivers, inferred
  latches, combinational loops, incomplete assignments and undriven signals;
- run the full v0.1 golden regression with unchanged expected values;
- run every new directed test for the feature, including reset during activity,
  boundary values, invalid/unmapped transactions and simultaneous masters where
  applicable;
- check outputs and `uio_oe` for deterministic reset, idle and active states;
- include assertions or scoreboard checks for one-shot strobes, no duplicate
  writes, bounded completion and no lost transaction;
- regenerate any firmware image from its source and verify the generated image
  matches the committed file.

Verification must target observable behavior. A test that only watches internal
debug state does not replace an externally visible end-to-end test.

## 5. Gate 3: synthesis before accepting RTL

Run the same synthesis configuration for baseline and candidate, then compare:

- mapped cell count and cell area;
- sequential cells / FF and combinational cells;
- mux count and high-fanout control signals;
- memory inference and any memory mapped to FFs;
- removed/dead logic and whether CPU, MMIO, QSPI and Hasemi remain reachable;
- latch, lint, synthesis and mapping warnings.

Every material delta must have an explanation tied to the changed logic. Reject
or investigate any unexplained increase, unexpected inferred memory, removed
functional logic, or area result inconsistent with the 3x2 budget. Synthesis
PASS alone is not a FIT decision.

## 6. Gate 4: early physical feedback

Run the target Tiny Tapeout SKY26d 3x2 hardening flow on the candidate before
calling the feature complete. Review intermediate placement and routing as soon
as available; do not wait until the end of a large feature batch.

Record, at minimum:

- die/core dimensions, target density, placed utilization and standard-cell area;
- placement/global-route congestion and detailed-route violation trend;
- final route DRC, antenna, Magic DRC, LVS and Tiny Tapeout precheck;
- setup and hold WS/WNS/TNS by corner, including the worst margin;
- max slew, capacitance and fanout violations;
- unconstrained/unannotated paths and flow warnings;
- GLS against the same functional test matrix;
- exact commit SHA and artifact/run links.

An intermediate DRT violation count is diagnostic evidence, not a final DRC
result. A long-running or non-converging route is a physical blocker until the
flow completes or fails; it must not be reported as PASS.

## 7. Gate 5: keep or revert

Keep a change only when all of these are true:

- golden v0.1 behavior still passes;
- new requirements have passing directed and integration tests;
- synthesis has no unexplained growth, dead block or unintended memory;
- 3x2 hardening completes with acceptable utilization and routing;
- setup and hold meet the declared clock across reported corners, with useful
  margin and no artificial exceptions;
- DRC/LVS/antenna/precheck are clean under the selected flow;
- GLS passes the regression coverage required for the changed behavior;
- the report contains reproducible metrics and exact provenance.

If any gate fails, preserve the failing evidence, revert or revise the candidate,
and repeat from RTL verification. Do not make a later stage appear clean by
deleting its earlier failure evidence.

## 8. Optimization order for the current TinyQV integration

Use measured contribution rather than source length to choose work:

1. Obtain final same-SHA synthesis and physical reports; classify whether the
   main constraint is cell area, sequential area, a critical logic path,
   high-fanout repair, placement density, or QSPI routing congestion.
2. Inspect the mapped hierarchy and register-file cells to distinguish CPU
   cost from Hasemi, bridge, QSPI and physical-repair cost.
3. Form one optimization hypothesis and change one logical block per experiment.
4. Preserve TinyQV upstream files; prefer wrapper-level pruning only when the
   memory map and specified interface permit it.
5. Run the complete functional tests and synthesis immediately; run 3x2
   hardening before keeping any change intended to improve physical fit.
6. Compare the same metrics against the previous source and golden v0.1.

Do not begin by rewriting `risk_engine` or the TinyQV core. The route image
captured during the v0.2 run showed detailed-route violations rising to 21,842
at 90% of the first optimization iteration. This is an early congestion warning;
the final route result for commit `c6e7b80553c20cb503152ae145a8ebb3ca218372`
was still pending at the time this plan was written. First establish whether
the final blocker is global density, pin access, QSPI bus geometry, or cell
count, then choose the smallest change that addresses the measured cause.

### Candidate experiments, gated by reports

| Candidate | Start only when evidence shows | Required check |
|---|---|---|
| Balance the four-term `risk_engine.score_sum` addition tree | that sum path limits setup margin | Exhaustively compare all 4 sensor severities/weights and thresholds against golden behavior; compare mapped cells and routed STA |
| Reduce or remove optional PSRAM B support | B select/decode contributes measurable area or pin-access pressure | Confirm reserved-memory behavior and board contract; run all QSPI, boot and reset tests plus full hardening |
| Change TinyQV register-file/control implementation | mapped FF/mux structure is a dominant, quantified area term | Keep upstream copy intact; treat replacement as a separately attributed subsystem and run CPU instruction, ABI, interrupt, MMIO and memory tests |
| Change reset/fanout or localize enables | reports identify reset/control nets as repair or slew contributors | Verify reset assertion/deassertion, repeated boot, mid-transaction reset, GLS and all-corner STA |
| Change QSPI output-enable or pin grouping | route reports identify QSPI pin access/contention as the cause | Prove every command/address/read/write direction and reset/idle state; rerun pin check, contention test, GLS and DRC |

None of these is an approved RTL change until its start condition is met. A
smaller source file or fewer lines is not evidence of a smaller circuit.

## 9. Change record template

Copy this block into the pull request or optimization note for each experiment:

```text
Change ID / commit:
Requirement or measured issue:
Baseline commit and tool versions:
Modules/interfaces changed:
Functional invariants:
Tests added or run:
Synthesis hypothesis:
Physical hypothesis:
RTL/lint/regression result:
Synthesis delta:
P&R / STA / DRC / LVS / antenna / precheck / GLS:
Warnings and unresolved issues:
Decision: keep / revise / revert
Rollback point:
```
