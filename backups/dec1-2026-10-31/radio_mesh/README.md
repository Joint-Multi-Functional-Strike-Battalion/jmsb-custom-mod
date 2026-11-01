# Radio Mesh

`jmfsb_radio_mesh`

The ACRE2 radios are a mesh. A transmission that cannot reach a receiver
directly is carried by friendly radios on the same frequency - as many hops
as it takes - with every leg judged by ACRE's own propagation model (terrain,
antennas, power), so a manpack on a ridge or a vehicle rack in the valley
extends the net the way a real repeater would. Direct is preferred whenever it
is the stronger link, and with no relay in reach the result is exactly ACRE's.

* **Off by default.** The *Enable mesh relaying* server setting turns it on;
  off, the result is ACRE's own point-to-point signal, still scaled by jamming.
* **Relays** are the manpacks and vehicle racks - PRC-152 and PRC-117F by
  default - carried by players or racked in vehicles. The PRC-148 squad
  handheld is an end point, never a relay. Same side only.
* **Hops** are unbounded; the route taken is the one whose weakest leg is
  strongest (a widest-path search over the relays in reach).
* **Loss**: a relay transmitting under the power threshold (1 W by default)
  costs a fraction of audio quality per hop; a relay at or above it repeats
  cleanly. Reception itself is never penalised by a hop.
* **Jamming** still applies on top - this addon took over the one custom
  signal function ACRE allows from `jmfsb_jamming` and applies its jam level
  itself.

Settings under *JMSB - Voice (ACRE) > Radio Mesh* (the ACRE page; the choice of
voice system is on JMSB - Voice): enable (off by default), relay radio classes,
loss per weak hop, the power threshold, the relay-table refresh, and the cap
on relays examined per transmission.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `cba_xeh` _(external)_
- `cba_settings` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

4 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_radio_mesh_enabled` | CHECKBOX | Enable mesh relaying |
| `jmfsb_radio_mesh_nodeRadios` | EDITBOX | Relay radios |
| `jmfsb_radio_mesh_hopLoss` | SLIDER | Loss per weak hop |
| `jmfsb_radio_mesh_lossBelowMw` | SLIDER | Weak-hop threshold (mW) |
| `jmfsb_radio_mesh_refresh` | SLIDER | Relay table refresh (s) |
| `jmfsb_radio_mesh_maxNodes` | SLIDER | Relays considered per transmission |

## Functions

<details><summary>4</summary>

- `jmfsb_radio_mesh_fnc_edge`
- `jmfsb_radio_mesh_fnc_radioSide`
- `jmfsb_radio_mesh_fnc_refreshNodes`
- `jmfsb_radio_mesh_fnc_signal`

</details>
