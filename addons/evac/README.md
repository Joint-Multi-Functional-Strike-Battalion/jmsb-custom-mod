# Evac

`jmfsb_evac`

Medic-gated evacuation replacing respawn: a medic heals the real player
onto themselves and a permanently unconscious clone is left behind carrying the
same loadout and injuries.

With Advanced Combat Medicine (ACM) loaded the whole system stands down - ACM
brings its own evacuation - and the action never appears.

The medic's machine asks the server by `remoteExecCall` to `fnc_evacServer`.
The server trusts none of it (review S6). The medic is the sending machine's
own player. He must be alive and within 10 m of the casualty. The action's
gate runs again on the server: a downed living player, not himself, and an
ACE medic if Medics Only is on. One casualty cannot be evacuated twice
within 10 s. A refusal is shown to the medic as "Failed.".

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `ace_interact_menu` _(external)_
- `ace_common` _(external)_
- `ace_medical` _(external)_
- `ace_medical_treatment` _(external)_

## Ships

4 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_evac_enabled` | CHECKBOX | Enable Medic Evac |
| `jmfsb_evac_medicOnly` | CHECKBOX | Medics Only |
| `jmfsb_evac_time` | SLIDER | Evac Time (s) |

## Functions

<details><summary>4</summary>

- `jmfsb_evac_fnc_canConvert`
- `jmfsb_evac_fnc_convert`
- `jmfsb_evac_fnc_convertAction`
- `jmfsb_evac_fnc_evacServer`

</details>
