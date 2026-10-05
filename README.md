# RedM interactions

Configurable interactions with objects or points on the map.

# Requirements

- [uiprompt](https://github.com/kibook/redm-uiprompt)

# Install

1. Create a folder named `interactions` in your resources folder.

2. Copy the files in this repository to that folder.

3. Add `start interactions` to `server.cfg`.

## BS controls

- Arrow Down: open the nearby furniture/interaction picker. Arrow keys select;
  Enter starts the selected interaction, Escape closes the picker.
- Arrow Up: immediately stop an active interaction and return to the starting
  position. The “Aufstehen” prompt replaces “Nutzen” while interacting.
- Arrow Left/Right: silently turn while standing still (90 degrees per second, with a
  configurable 0.2-second acceleration ramp).
  Turning never registers or displays a prompt.

Configure `InteractControl`, `StopControl`, `StopLabel` and `Turn` in `config.lua`.
Set `Turn.enabled = false` to disable turning. A nil interaction/stop control
turns off that binding and its prompt.

Inputs are blocked during death, mounting/riding, vehicle use, combat,
ragdoll/falling/climbing/swimming, restraint, pause, NUI focus and open Feather or
VORP menus. Turning additionally requires standing still, enabled movement
controls, no scenario, no attachment and no aiming/shooting. Custom menus or
activities without focus/control locks must return true from
`Config.IsInputBlocked`. There is no universal detector for arbitrary custom UI.
Death hides both prompts every frame and releases this resource’s position lock
without moving the character or clearing death tasks. Interrupted interactions
are no longer restarted automatically.

Verify in RedM: left/right direction and speed; both keys together; WASD;
furniture picker; immediate Arrow Up during entry/idle; death while sitting;
horse mounting/riding; vehicles; Feather and VORP menus with and without cursor;
resource stop during interaction. New code is developed on BSDev; deploy and
restart on BS-Live separately.

### Input diagnostics

Run `/interactionsdebug` and read F8 output to see the actual blocking reason,
nearby interaction state and prompt state. Death detection uses the checks from
`zata_Camps` (invalid ped, entity dead, dead/dying with both flags), normalizing
numeric zero to false. Player-control locks block silent turning; they do not
classify a living player as dead or independently hide the stop prompt.
Failed optional menu exports log once and fall back to NUI focus and Feather/VORP
open/close events instead of permanently hiding every furniture prompt. False
entries in VORP's opened-menu table are ignored.

Regression test: `lua tests/input_gates_test.lua` from this resource directory.

Turning inputs and blocking conditions are checked every rendered frame.
`Turn.accelerationSeconds` controls the smooth start/reversal (0 disables the ramp).
Releasing the keys or entering a blocked state stops rotation immediately.
Stationary turning uses the speed threshold and rejects movement inputs; it does
not depend on the potentially fluctuating `IsPedStill` state. Furniture proximity
is scanned every 500 ms independently of turning.

While seated through this resource, Arrow Down remains available alongside
Arrow Up to reopen the interaction picker and switch poses without standing up.

Choosing Cancel in the picker also immediately clears native/external seating
and other player animations. For external seating, the player stays at the
current position. Turning movement axes use a 0.1 dead zone.

For stationary turning diagnosis, run `/interactionsturndebug`, close the
console/chat, and hold each arrow key while standing. It logs for ten seconds
at 500 ms intervals: the exact current turn-block reason, movement axes,
normal/disabled key readings in input groups 0–2, and actual/last requested
heading. Diagnostic logging is inactive by default and does not unlock controls.

Stationary turning reads held keyboard state using `Turn.leftRawKey` (0x25)
and `Turn.rightRawKey` (0x27), avoiding game-menu repeat pulses resetting the
acceleration ramp. Change the virtual key codes to rebind keyboard turning;
set both to false to use only the configured game controls. Existing disabled
control and menu/movement gates still apply; raw input creates no prompts.
