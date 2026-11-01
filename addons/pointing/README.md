# Pointing

`jmfsb_pointing`

Pointing gestures.

In a vehicle, the point key sends the point by `remoteExecCall` to the
server's `srvPoint`, which takes the pointer from the sender, checks he is in
a vehicle (not a static weapon) and the point is in reach, and sends it to the
crew's `pointed`, which takes it only from the server and hands it to DUI's
radar. It was the `jmfsb_pointing_pointed` CBA event, which any client could
raise to show any man pointing (review R1).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_common`

## Ships

3 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_pointing_vehicleEnabled` | CHECKBOX | Enable pointing in vehicles |

## Functions

<details><summary>3</summary>

- `jmfsb_pointing_fnc_keyPressVehicle`
- `jmfsb_pointing_fnc_pointed`
- `jmfsb_pointing_fnc_srvPoint`

</details>
