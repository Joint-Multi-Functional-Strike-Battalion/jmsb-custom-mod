# Safestart

`jmfsb_safestart`

The safe-start hold that keeps a mission frozen until it is time.

At start the player's weapon goes on his back (`lowerWeapon`) and, with
Lock weapon on and ACE safe mode loaded, its safety goes on (`enableSafety`).
Both are plain calls on the player's own machine; `lowerWeapon` on a unit
local elsewhere is sent there by the server alone. They were CBA events any
client could raise to make anyone sling his weapon (review R1).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_common`

## Ships

5 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_safestart_startLocked` | CHECKBOX | Lock weapon |

## Functions

<details><summary>5</summary>

- `jmfsb_safestart_fnc_enableSafety`
- `jmfsb_safestart_fnc_grenadeBindCondition`
- `jmfsb_safestart_fnc_grenadeBindWarn`
- `jmfsb_safestart_fnc_lowerWeapon`
- `jmfsb_safestart_fnc_openKeybinding`

</details>
