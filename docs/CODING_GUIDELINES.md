# Coding guidelines

This mod follows the **ACE3 coding guidelines**: <https://ace3.acemod.org/wiki/development/coding-guidelines>.
They are written out here because they are binding for every addon in `addons/`, hand-written or generated.
The generators in `tools/` must emit code that already obeys them.

Not a generated file. Edit it by hand when the rules change.

## Macros: never write by hand what a macro builds

Every addon includes `script_component.hpp`, which pulls in CBA's macros through `addons/main/script_macros.hpp`.
The prefix is `jmfsb`, the component is the addon folder name.

| Macro | Expands to | Use it for |
|---|---|---|
| `GVAR(x)` | `jmfsb_<component>_x` | a global variable or a class this addon owns |
| `QGVAR(x)` | `"jmfsb_<component>_x"` | the same, quoted |
| `EGVAR(c,x)` / `QEGVAR(c,x)` | another component's global | reaching into component `c` |
| `FUNC(x)` / `QFUNC(x)` | `jmfsb_<component>_fnc_x` | a function of this addon |
| `EFUNC(c,x)` / `QEFUNC(c,x)` | another component's function | |
| `PATHTOF(p)` / `QPATHTOF(p)` | `\z\jmfsb\addons\<component>\p` | this addon's own file |
| `PATHTOEF(c,p)` / `QPATHTOEF(c,p)` | `\z\jmfsb\addons\c\p` | another addon's file |
| `LSTRING(k)` / `CSTRING(k)` | `STR_jmfsb_<component>_k` | localised text |
| `QUOTE(...)` | the argument, quoted | any macro that must appear as a string in config |
| `QAUTHOR` | the mod's author string | every `author =` |

**A literal `\z\jmfsb\addons\...` path in a config is a defect.** The only exception is `#include`, which the
preprocessor resolves before macros exist.

**Class names are the one place the prefix is written out.** A faction's vehicles are named after the faction
(`jmfsb_EUDF_B_MRAP_01_F`), not after the component, so `GVAR` cannot produce them; renaming them would break every
mission, group and camo entry that refers to them. Inside an addon that owns its classes outright, use `GVAR`.

## SQF

- One function per `.sqf` file. `PREP` it; never define functions inline.
- Every file-based function carries the ACE header: author, description, `Arguments:` with numbered
  `<TYPE>` entries, `Return Value:`, `Example:`, `Public: Yes|No`.
- Types are uppercase in angle brackets: `<OBJECT>`, `<ARRAY of STRINGs>`, `<STRING or CODE>`.
- `private` on every local variable at its first assignment; `params` for arguments.
- 4 spaces per level, no tabs, no trailing whitespace. Opening brace on the same line, closing brace on its own.
- One space after a comma in arrays: `[_unit, _vehicle]`.
- Conditions always in brackets: `if (_x) then {...}`.
- No magic numbers: `#define` them in the file header or in `script_component.hpp`.
- No globals to pass data between functions; pass arguments. No constant globals; use `#define`.
- `getVariable` always with a default, or the result's type is checked.
- Avoid `spawn`, `execVM`, infinite `while`, and `waitUntil` (use `CBA_fnc_waitUntilAndExecute`).
- No commented-out code, no unreachable code. Functions stay under 250 lines excluding the header.

## Config

- `config.cpp` holds `CfgPatches`; everything else lives in its own `.hpp` and is `#include`d.
- Declare an external class before you inherit from it, including nested ones you extend
  (`class Turrets { class MainTurret; };`), or HEMTT reports L-C04.
- `author = QAUTHOR;` everywhere.
- User-facing text goes in `stringtable.xml`, referenced with `CSTRING`. The exception the user has asked for
  repeatedly: **appearance-menu names are written as plain text, never `$STR_` keys**.
- Only name an editor subcategory the game or this mod defines. Inventing one logs
  `No entry 'bin\config.bin/CfgEditorSubcategories...'` at every start.

## Trust: the server never believes a client (code review R1/R2, 2026-10-31)

- CBA events carry no sender (they travel as public variables): any client can raise any of them. A request the
  server must trust goes by `remoteExec` / `remoteExecCall` to a PREP'd function.
- That function checks at its top, before any `spawn` (inside spawned code the sender is unknown):
  `EFUNC(common,sender)` (the real machine, unit and Steam id), `[_unit] call EFUNC(common,senderIs)` (a unit
  named in the arguments is the sender's own), `EFUNC(common,senderIsAdmin)` (an admin by the server's records).
- Never take a unit, side, requester, callsign, Steam id or count from the arguments when the server can work it
  out. Re-run the client's own checks (canTask, side, range, cooldown, "did the hack finish") on the server.
- Work the server pushes to a client goes by `remoteExec`, and the client checks `EFUNC(common,fromServer)`.
- What the server decides on (admin list, grants, cooldowns, ledgers) lives in `localNamespace`, which is not
  networked. Any client can `publicVariable` any `missionNamespace` name over the server's copy; a public copy is
  for screens only and the server never reads it back.
- Admin is `EFUNC(common,senderIsAdmin)` on the server. The public flag `jmfsb_common_isAdmin` is for screens.
- Secrets never go in a CBA setting (every server setting reaches every client): the server's environment.
- A new client-to-server function goes on the whitelist list in docs/SETUP.md.

## Locality (code review R5)

- Never use `player` in server code; use the unit passed in, or the sender.
- Fired handlers act only where the projectile or the shooter is local (`local _projectile`).
- AI orders, `moveOut`, `setDamage` on a unit and similar run on the machine that owns the unit: send them there.
- Killed handlers: `MPKilled`, or register where the unit is local and decide on the server.
- No `waitUntil` or `sleep` in anything a handler or a `call` can reach; use `CBA_fnc_waitUntilAndExecute` /
  `CBA_fnc_waitAndExecute`.
- Read another addon's variables only after its init: list it in `requiredAddons`, and read every cross-addon
  flag that may be absent with `getVariable [name, default]`. Functions of an optional mod (ACE, ACM, ALiVE through
  adapter_alive, messaging) are checked with `isNil` first (R6).
- Read settings only after `CBA_settingsInitialized`; never overwrite a setting's value after the settings include.

## The network budget (code review R7)

- Broadcast only what another machine reads, only when it changes, and only to who needs it:
  `publicVariableClient` / `remoteExec` to one owner beats a public variable to all.
- No public `setVariable` inside a loop, a per-frame handler or a damage handler; compare first and set only on a
  change.
- Progress and timers go out in coarse steps (start, quarters, done), not every second.
- A server-only handler gets a server event, not a global one.
- Big tables (the PAC roster) send what changed, and clients re-apply only what changed.
- UI: build controls once, change text, colour and visibility on a tick, recreate only when a change key differs,
  one redraw per frame, never recreate a render-to-texture picture on a tick (R8).

## Before you say it is done

`python tools/check_all.py` is the gate: `hemtt check` plus nine project checks (SQF validation, config style,
stringtables, generated art, addon READMEs, architectural invariants, plumbing, externals, CfgPatches). `hemtt
check` alone is not the gate. Regenerate what it says is stale rather than hand-editing generated files.
