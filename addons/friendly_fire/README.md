# Friendly Fire

`jmfsb_friendly_fire`

What happens when somebody shoots their own side.

With logging on, a player hit by a player of his own side writes the line to
his own RPT and sends it by `remoteExecCall` to the server's `log`, which takes
the victim from the sender and checks the shot again (a player, the same side,
not himself). It was a global CBA event, which any client could raise to
forge FF lines naming anyone in every machine's RPT (review R1); the line is
now in the victim's and the server's RPT, not every client's.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_common`

## Ships

1 function.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_friendly_fire_loggingEnabled` | CHECKBOX | Friendly fire logging |

## Functions

<details><summary>1</summary>

- `jmfsb_friendly_fire_fnc_log`

</details>
