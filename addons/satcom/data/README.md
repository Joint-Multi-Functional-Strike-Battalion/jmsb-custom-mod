# SatCom

Ported from **[AZM SatCom](https://github.com/alezm00/Satcom)** by Alezm, released
under **The Unlicense** — public domain, so it can be copied, modified and
redistributed without restriction. Nothing here is under a share-alike or
copyleft term.

| File | Source | Used for |
|---|---|---|
| `satcom_icon.paa` | `@AZM_SatCom/addons/azm_satcom/data/satcom_icon.paa` | Item picture and the interaction icons |

That icon is the only asset. Both models are vanilla:

- item — `\a3\Props_F_Enoch\Military\Equipment\BatteryPack_01_Closed_F.p3d`
- deployed mast — `\A3\Props_F_Enoch\Military\Camps\SatelliteAntenna_01_F.p3d`

## What changed in the port

- Re-prefixed to jmfsb's naming: `jmfsb_satcom_item`, `jmfsb_satcom_deployed`.
- **No ACRE2.** The original hard-required `acre_main`; jmfsb's version is a
  plain deployable mast, which `patrol_base` uses as its base beacon. The ACRE2
  antenna, its Connect / Disconnect Radio actions and `jmfsb_satcom_fnc_hasAcre`
  were removed on 2026-10-31 (DEC1: TFAR and ACRE are no longer voice options).
- Pack Up refuses on a mast that is anchoring a patrol base — see
  `jmfsb_satcom_fnc_canPickUp`.
- Deploy re-checks the carried item, and the delayed pick-up re-checks the mast
  still exists, so neither can be raced.
