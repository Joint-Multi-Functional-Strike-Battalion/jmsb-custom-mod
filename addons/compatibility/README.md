# Compatibility

`jmfsb_compatibility`

Load-order glue for base-game and CDLC content that has to be
present before jmfsb's own classes resolve.

Optional radio-mod patches (each `skipWhenMissingDependencies`, so they load
only with that mod; class names never change):

- `tfar_radios` (needs `tfar_core`, `tfar_handhelds`, `tfar_backpacks`): the
  MPU5 and TW-950 become TFAR short range radios again (`TFAR_anprc152` parent,
  `tf_prototype`, `tf_parent`, TFAR's numbered instances, the MPU5's own
  open-radio screen), and the radio bags of `jmfsb_backpack`, `jmfsb_uniform`
  and `jmfsb_uniform_ru` (and so `jmfsb_mpu5_lr`) TFAR long range sets, with the
  1268 build's `tf_` values (RT-1523G dialog / west code, Bussole / east code
  on the CSAT and RU bags).
- `tfar_cdlc_ws` (needs `jmfsb_compatibility_cdlc_ws` and TFAR): the WS
  overlay's MCU-D radio bag likewise.
- `tmt_tfar_labels` (needs `TMT_Gear`): TMT's radio backpacks' TFAR Eden
  attributes in plain text, so a modset WITHOUT TFAR does not fill the RPT with
  missing `$STR_tfar_static_radios_*` strings (restored 2026-10-20).

There is no ACRE patch: ACRE's radios are its own items, programmed by
`jmfsb_gear_fnc_setupRadios`.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `A3_Data_F_Decade_Loadorder` _(external)_
