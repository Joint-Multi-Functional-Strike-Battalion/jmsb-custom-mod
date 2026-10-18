# Nvg

`jmfsb_nvg`

Gets the player's selected NVG effect and checks if ACE is running.

## JMSB goggles

Every NVG in the JMSB arsenal has a JMSB version, `jmfsb_nvg_<original>` (and
`jmfsb_headware_mig_MIG_*` for MIG's, from `tools/gen_mig.py`). Each inherits the
original - model, picture, generation, phosphor - and changes only the view:

- **Full screen**: `modelOptics` is the empty reticle, and ACE's border and eye
  cups are cleared, so no tube mask is drawn. Each is marked
  `jmfsb_nvg_fullScreen = 1`.
- **Tube mask, per player**: the client setting **NVG full screen**
  (1st Joint Multi-Functional Strike Battalion > NVG, default on). Off, a JMSB
  goggle in NVG mode is seen through its tubes again: ACE's own mask for the
  goggle it was made from (the first `ACE_nightvision_border` up its parents,
  else ACE's binocular mask), drawn as a picture on the mission display and
  put up or taken down on events only (vision mode, loadout, weapon, unit,
  vehicle, view, Zeus/feature camera, the setting) - never per frame. Not in
  Zeus, a turret sight or the binocular. It sits under ECOTI's HUD, and the
  phosphor colour effect is untouched (that is a post-process; the mask is UI).
  Unlike ACE's it does not grow as you zoom.
- **ECOTI**: `visionMode[] = {"Normal", "NVG", "TI"}`, `thermalMode[] = {0, 1}`
  and `jmfsb_ecoti_enabled = 1` - see `jmfsb_ecoti`.

Here: the jmfsb ADV NVG / NVG v5 sets, and versions of the vanilla and ACE
goggles. The EF LP NVGs are in `compatibility/cdlc_ef` and the RF Ti Goggles in
`compatibility/cdlc_rf` (`tools/cdlc_split.py`); the Aegis IVAS and scrim nets in
`compatibility/aegis_nvg`, which loads only with Aegis. This addon needs no
creator DLC.

**Through the scope.** The goggles see through every scope
(`compatibility/nvg_optics_*`, see the optics README). CBA's picture-in-picture
scopes render their magnified view with their own camera, pinned to normal
vision; `FUNC(syncPipVision)` puts that view in the goggle's mode (day, NVG or
thermal) four times a second while aiming down a sight.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_common`
- `cba_main` _(external)_
- `ace_nightvision` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

7 weapon/item classes, 8 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_nvg_showFullScreen` | CHECKBOX | NVG full screen |

## Functions

<details><summary>8</summary>

- `jmfsb_nvg_fnc_getNvgEffect`
- `jmfsb_nvg_fnc_getVisionMode`
- `jmfsb_nvg_fnc_maskHide`
- `jmfsb_nvg_fnc_maskShow`
- `jmfsb_nvg_fnc_maskTexture`
- `jmfsb_nvg_fnc_setNvgEffect`
- `jmfsb_nvg_fnc_syncPipVision`
- `jmfsb_nvg_fnc_updateMask`

</details>
