# Radios

`jmfsb_radios`

The radio family. Today: two MANET handhelds, the **MPU5** and the **TrellisWare TW-950**, and the **MPU5 manpack** - plain JMSB items, no radio mod.

## What a set is

Voice is Arma 3's own VON (docs/DESIGN_VOICE.md). `jmfsb_mpu5` and
`jmfsb_tw950` are vanilla `ItemRadio` items: in the radio slot they open VON's
radio channels. `jmfsb_mpu5_lr` is a radio bag (our Multicam radio pack under
its own name until there is an MPU5 manpack model). Each names its RF profile
in config - `jmfsb_rf_profile`: `handheld`, `legacy` and `manpack` - which is how
`jmfsb_rf` recognises it as a set (`jmfsb_rf_fnc_itemProfile`,
`jmfsb_rf_fnc_carriedSets`). `Item_jmfsb_mpu5` and `Item_jmfsb_tw950` are the
editor and Zeus placeables. The class names are the ones loadouts, the PAC
database and the arsenals carry.

**No radio dialog.** The radio UI is the device's RADIO app. The MPU5 dialog
picture (`data/mpu5_dialog_ca.paa`) is still generated and shipped for it.

**Under TFAR they are TFAR sets** (2026-10-20, "keep the ACRE and TFAR"). This
addon stays plain so VON needs no radio mod; the optional patch
`jmfsb_compatibility_tfar_radios` (addons/compatibility/tfar_radios, loaded
only with `tfar_core`, `tfar_handhelds` and `tfar_backpacks`) re-parents
`jmfsb_mpu5` and `jmfsb_tw950` on `TFAR_anprc152` with `tf_prototype`,
`tf_parent`, TFAR's numbered instances (`_1` to `_1000`, TFAR's own
`TF_RADIO_IDS`) and the MPU5's own open-radio screen
(`jmfsb_mpu5_radio_dialog`, on `data/mpu5_dialog_ca.paa`), and gives the radio
bags - `jmfsb_mpu5_lr` through our radio pack base - their TFAR long range
properties. Under TFAR a handheld wears the PRC-152's model (inherited); the
generated MPU5 mesh is still not worn. Class names and `jmfsb_rf_profile` are
unchanged.

**On the ground** a dropped handheld wears `ItemRadio`'s own model (inherited):
the generated MPU5 mesh was reported invisible on the ground and is not worn
until it has been looked at in game.

## The model and textures are generated

`data/` is the output of `tools/gen_radios.py`, which reads the purchased
3DMA assets at `Radio_MPU5_v01/` and `Radio_TrellisWare_v01/` in the repo
root. **Those sources are gitignored and never committed**; the derivatives
here are what ships. One table in the script says which meshes of which OBJ
make which radio; adding a radio is one row.

Per radio `<id>`:

- `<id>.p3d` - MLOD, written directly by the script from the OBJ: a visual
  LOD (MPU5: body and PTT - the pouch, patch and tablet meshes in that asset
  are other items, left for later; TW-950: body and the long antenna, the two
  shorter antennas being alternates), a box geometry LOD carrying the mass,
  and four land-contact points. Underside on y = 0, autocenter off, so a
  dropped radio lies on the ground. `hemtt build` binarizes it, and that is
  the validator: a malformed LOD fails the build.
- `<id>_co.paa` - base colour at 2048.
- `<id>_smdi.paa` - Arma's specular map from the asset's metalness and
  roughness: G specular, B gloss.
- `<id>_nohq.paa` - the normal map, generated but **not wired into the
  rvmat yet**: Arma's `_nohq` channel convention is not a plain RGB
  conversion, and a wrong normal map looks worse than none. Switch Stage1 of
  `<id>.rvmat` to it once it has been looked at in game.
- `<id>_icon_ca.paa` - the inventory icon, a flat-shaded top view rendered
  by the script.

`hemtt utils paa convert` refuses to overwrite and exits 0 doing it; the
script deletes the target first. Worth knowing before trusting any other
converter call in this repo.

Two switches in the script exist for the two things that cannot be verified
without the game: `FLIP_WINDING` if faces render inside-out, and
`NEGATE_NORMALS` if the lighting does.

## Licence

The 3DMA asset is a commercial purchase; the licence tier for redistribution
in a free mod is **unresolved** (docs/SPEC_TACNET.json, open). Do not ship a
release with this addon until it is.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_backpack`

## Ships

3 unit classes, 2 weapon/item classes.
