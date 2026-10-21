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

`StartInteractionAtObject` bietet vor der Umrechnung in Weltkoordinaten den
synchronen Hook `zata_Zeppelin:client:startBenchInteraction` an. Erkannte
Zeppelinbänke mit Szenario werden vollständig von der Zeppelinseite gestartet:
`CREATE_SCENARIO_POINT_HASH_ATTACHED_TO_ENTITY` bindet den Sitzpunkt an die echte
Bank, `TASK_USE_SCENARIO_POINT` startet ausschließlich diesen Punkt. Es gibt für
Szenariositze keinen parallelen Welt-Szenariostart, Ped-Attach oder laufenden
Ped-/Szenariopunktteleport. Fehlende Bindung und Eintrittsfehler werden beendet;
es wird kein zweiter Bewegungsmechanismus zugeschaltet.

Normale Möbel behalten ihren bisherigen Start. Reine Animationen ohne Szenario
behalten ebenfalls `StartInteractionAtCoords`; nur für erkannte Zeppelinbänke
meldet der anschließende Hook `benchInteractionStarted` die Animation an einem
eigenen Ped-Transformpfad an. Der Nachstart-Hook läuft nur, wenn der normale
Start tatsächlich die aktuelle Interaktion gesetzt hat.

Zeppelininteraktionen markieren `zeppelinBench` und verlassen die Rückkehr zur
alten Weltposition. Beim Aufstehen beendet `StopInteraction` die alte Aufgabe
vor dem Zeppelin-Stop-Hook, damit dessen Deck-Warmup nicht nachträglich durch
`ClearPedTasksImmediately` gelöst wird. Der zusätzliche lokale Hook
`zata_Zeppelin:client:benchInteractionEnded` entfernt nach einem selbst erkannten
Abbruch ausschließlich den Adapterzustand, ohne neue Aufgaben, Attach-Verbindungen
oder Positionen anzutasten. Stop-, Status-, Vorstart-, Nachstart- und Ende-Hook
bei Upstream-Updates gemeinsam erhalten.

`zata_Zeppelin/tests/bench_attachment_test.lua` prüft vollständige Signaturen,
Bankbindung, genau einen Bewegungspfad, kleine Park-/Flugschritte, Ein-/Ausstieg,
Timeout, Punkt-/Bankverlust, fremde Aufgaben, Teleport, Tod, Pedwechsel und
Resource-Stopp. Der Test simuliert keine native Sitzphysik. Native RedM-Mitnahme
und Ped-/Szenariosynchronisierung auf mehreren Clients sind im Spiel zu prüfen.
Die allgemeinen Eingaben prüft `tests/input_gates_test.lua`.

## Schachtische von zata_Chess

`client.lua` fragt vor den allgemeinen Eingaben den optionalen Client-Export
`exports.zata_Chess:blocksInteractions()` ab. Nur am Schachtisch oder während
seiner Platzierung/Sitzung blendet redm-interactions seine eigenen Prompts aus.
Fehlt die Resource oder der Export, bleibt das bisherige Verhalten erhalten.
Prüfung: Schach-Hocker mit B, Brettkamera mit G, Aufstehen mit B; außerhalb
bleiben normale Möbelinteraktionen verfügbar. Kein NUI-Fokus wird dafür erzwungen.

## Sitzstatus bewegter Zeppelinbänke

Der Möbel-Watchdog fragt für `zeppelinBench` synchron den lokalen Hook
`zata_Zeppelin:client:benchInteractionActive` ab. Die Zeppelinseite hält damit
auch die begrenzte Eintrittsphase exklusiv und
prüft anschließend den tatsächlich verwendeten bankgebundenen Punkt. Ein
GENERIC-Szenario darf auf einen anderen Punkt derselben Bank auflösen;
`scenario=0` wird nicht als unbewiesener Fertig-Check verwendet. Normale Möbel
behalten ihre bisherige Szenario-/Animationsprüfung. Beim Upstream-Update diesen
Hook zusammen mit den Start-/Stop-/Ende-Hooks erhalten.
