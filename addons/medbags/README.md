# MedBags

`jmfsb_medbags`

Medical bags and the items in them. Anyone may open the Boo Boo Bag, a Combat
Lifesaver (ACE medic class 1) the Medic Bag, and only a Medic (class 2) the
Trauma, Fluid and Drug kits. What each holds is a CBA setting below - ACE kit
by default, ACM's kit when ACM is loaded (`jmfsb_acm` re-defaults them).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `A3_Props_F_Orange` _(external)_
- `jmfsb_common`

## Ships

8 unit classes, 8 weapon/item classes, 16 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_medbags_contentsFirstAid` | EDITBOX | Boo Boo Bag contents |
| `jmfsb_medbags_contentsMedicKit` | EDITBOX | Medic Bag contents |
| `jmfsb_medbags_contentsTrauma` | EDITBOX | Trauma Kit contents |
| `jmfsb_medbags_contentsFluid` | EDITBOX | Fluid Kit contents |
| `jmfsb_medbags_contentsDrugKit` | EDITBOX | Drug Kit contents |
| `jmfsb_medbags_contentsMopp` | EDITBOX | MOPP Bag contents |
| `jmfsb_medbags_fillOrder` | LIST | Fill order |
| `jmfsb_medbags_fillOverflow` | CHECKBOX | Overflow to the ground |

## Functions

<details><summary>16</summary>

- `jmfsb_medbags_fnc_canTake`
- `jmfsb_medbags_fnc_canUnpackDrugKit`
- `jmfsb_medbags_fnc_canUnpackFirstAid`
- `jmfsb_medbags_fnc_canUnpackFluid`
- `jmfsb_medbags_fnc_canUnpackMedicKit`
- `jmfsb_medbags_fnc_canUnpackMopp`
- `jmfsb_medbags_fnc_canUnpackTrauma`
- `jmfsb_medbags_fnc_doTake`
- `jmfsb_medbags_fnc_doUnpackDrugKit`
- `jmfsb_medbags_fnc_doUnpackFirstAid`
- `jmfsb_medbags_fnc_doUnpackFluid`
- `jmfsb_medbags_fnc_doUnpackMedicKit`
- `jmfsb_medbags_fnc_doUnpackMopp`
- `jmfsb_medbags_fnc_doUnpackTrauma`
- `jmfsb_medbags_fnc_issueContents`
- `jmfsb_medbags_fnc_stripBag`

</details>
