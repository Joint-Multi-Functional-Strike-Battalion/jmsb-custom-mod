# Compatibility

`jmfsb_compatibility`

Load-order glue for base-game and CDLC content that has to be
present before jmfsb's own classes resolve.

There are no radio-mod patches. `tfar_radios`, `tfar_cdlc_ws` and
`tmt_tfar_labels` were removed on 2026-10-31 (DEC1): the voice is LiveKit, with
game VON as the server's fallback, and TFAR and ACRE are no longer voice
options.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `A3_Data_F_Decade_Loadorder` _(external)_
