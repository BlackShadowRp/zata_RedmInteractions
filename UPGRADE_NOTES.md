# BS changes to Kibook redm-interactions

Baseline: BlackShadowRp master `51e7246`, including live bed positions and labels.

- `config.lua`: configurable silent stationary turning and separate immediate
  stop control/label; custom input blocking hook.
- `client.lua`: frame-based death/input gates; optional Feather/VORP menu checks;
  separate stop prompt; frame-time-based turning; release interaction on death,
  ped replacement, interruption or resource stop instead of restarting tasks.
  Explicit stop restores the original position immediately; death preserves
  position/tasks. Nearby furniture detection remains throttled to 500 ms.
- `README.md`: bindings, integration limits and RedM verification checklist.

When updating upstream, preserve live furniture config and translations, and
reconcile upstream interaction lifecycle with these gates. Syntax and mocked
state tests cover prompt switching, rotation blocking and task cleanup. Actual
RedM animation/native behavior and menu interactions require in-game checks.

Prompt regression follow-up: match `zata_Camps` death checks, normalize numeric
native booleans, separate the player-control turning gate from furniture prompts,
and handle optional menu export failures via logged event/focus fallback. Added
`/interactionsdebug` and `tests/input_gates_test.lua`. The original reported
in-game blocking reason still requires the player's F8 diagnostic output.

Stationary turning now ramps to the configured speed over
`Turn.accelerationSeconds` (default 0.2 seconds), retaining immediate stop on
release/block. Movement inputs and the existing speed threshold replace
`IsPedStill` to avoid intermittent rotation gating. Verify smooth turns and
menu/mount/movement cancellation in game; regression coverage is in
`tests/input_gates_test.lua`.

Keep the interaction prompt and Arrow Down picker binding available during
active interactions, alongside the immediate Arrow Up stop binding. Pose
switching retains the original return position; silent turning stays disabled
while an interaction is active. Covered by `tests/input_gates_test.lua`.

Picker cancellation now clears the local player tasks even for native/external
seating, without inventing a return position. Resource shutdown and interruption
cleanup still only affect tracked interactions. Turning reads movement axes via
`GetControlNormal` with a 0.1 dead zone and normalizes boolean/0/1 results
for scenario, aiming, attachment and key gates. Verify native E seating cancel
and stationary turns in game; input regression tests cover external cancel and
numeric-zero scenario results.

Added `/interactionsturndebug` for ten-second client traces of turn blockers,
input groups and actual/requested heading. Turn gating is centralized in
`TurnBlockReason` without changing its conditions. This is diagnostic support
for an unresolved in-game rotation failure; mocked tests alone cannot identify
the live blocker or another resource overwriting the heading.

Use `IsRawKeyDown` for configured arrow virtual keys to keep rotation active
while held, independent of menu-control repeat pulses. Preserve disabled
control checks and all turn-block conditions. Debug traces now include the
resolved held state. Regression tests simulate a held raw key with intermittent
menu-control pulses, full-speed rotation, release, both keys and blocked input.
In-game confirmation remains required.
