# zata_RedmInteractions: Änderungen an kibooks Grundlage

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
`/zata_interactionsdebug` and `tests/input_gates_test.lua`. The original reported
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

Added `/zata_interactionsturndebug` for ten-second client traces of turn blockers,
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

## Mitbewegte Zeppelinbänke

`client.lua` fragt beim Start einer Objektinteraktion ausschließlich lokal
`zata_Zeppelin:client:startBenchInteraction` ab. Nur erkannte eigene Zeppelinbänke
werden übernommen; sonst bleibt der normale Möbelablauf aktiv. Beim Beenden
geht `zata_Zeppelin:client:stopBenchInteraction` an die Zeppelinseite. Der Spieler
kehrt dadurch nicht an die alte Weltposition vor der Fahrt zurück. Keine
zusätzlichen periodischen Netzwerk- oder Koordinatenpakete. Die Zeppelinseite
verwaltet Szenariopunkt, Netzwerk-Rumpfverbindung und sichere Deckrückgabe.
Bei Upstream-Updates diese beiden Hooks erhalten. Normale Möbel, Abbruch,
bewegter Sitz und Resource-Stopp werden mit Lua-Stubs geprüft; Mehrclient-Sitzen
und die nativen Szenarioanimationen sind zusätzlich im Spiel zu prüfen.

## Schachtische von zata_Chess

`client.lua` fragt vor den allgemeinen Eingaben den optionalen Client-Export
`exports.zata_Chess:blocksInteractions()` ab. Nur am Schachtisch oder während
seiner Platzierung/Sitzung blendet redm-interactions seine eigenen Prompts aus.
Fehlt die Resource oder der Export, bleibt das bisherige Verhalten erhalten.
Prüfung: Schach-Hocker mit B, Brettkamera mit G, Aufstehen mit B; außerhalb
bleiben normale Möbelinteraktionen verfügbar. Kein NUI-Fokus wird dafür erzwungen.

## Sitzstatus bewegter Zeppelinbänke

Der Möbel-Watchdog fragt für `zeppelinBench` synchron den lokalen Hook
`zata_Zeppelin:client:benchInteractionActive` ab. Dadurch beendet ein vom
GENERIC-Szenario abweichender konkreter Sitztyp nicht versehentlich den Sitz.
Normale Möbel behalten ihre bisherige Szenario-/Animationsprüfung.
Beim Upstream-Update diesen Hook zusammen mit den Start-/Stop-Hooks erhalten.
