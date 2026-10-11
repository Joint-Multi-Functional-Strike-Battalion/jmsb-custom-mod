# Medical: the lifesaver, the medic, and ACM

How the 1st JMSB divides ACM (Advanced Combat Medicine) between the two medical
skills TAC//PAC hands out, and what each bag and arsenal holds. The unit runs
ACM on every server; the mod's own medic evac is forced off behind it
(`jmfsb_evac_enabled = false` in the shipped `cba_settings`, and `jmfsb_evac`
stands down by itself when it sees `ACM_main`).

## The two skills

| PAC skill | ACE medic class | Who |
|---|---|---|
| **Combat Lifesaver** (`cls`, effects `medic:1`, `arsenal:cls`) | 1 | the rifleman who stops the bleeding, keeps an airway open and can decompress a chest |
| **Medic** (`medic`, effects `medic:2`, `arsenal:medic`) | 2 | everything that goes inside: advanced airways, chest tubes, lines, drugs, fractures |

ACM's permissions are three-way (ACE's "Anyone / Medics / Doctors" = classes
0 / 1 / 2), so the two skills map straight onto them.

## Who may do what

Set as DEFAULTS by `addons/acm` (`jmfsb_acm`, loaded only when ACM is), so a
server can still move a line in ACM's own settings menu. ACE's own medic levels
(`medicIV`, `medicEpinephrine`, `medicSurgicalKit`, `medicPAK`, `medicMorphine`,
`medicAdenosine`) are forced to 2 in the shipped `cba_settings`.

| Anyone (0) | Combat Lifesaver (1) | Medic (2) |
|---|---|---|
| tourniquet, pressure bandage, emergency trauma dressing, chest seal, SAM splint | OPA, NPA, suction bag | i-gel, cric kit, ACCUVAC |
| pulse oximeter, CPR, recovery position | inspect chest, needle decompression, AED | chest tube, thoracostomy |
| paracetamol, Penthrox, naloxone | elastic wrap, inspect for fracture | IV, IO, every drawn-up drug, fentanyl lozenge, fracture realignment |
| | ammonia inhalant, ATNA and midazolam autoinjectors | ACM's evacuation convert; ACE morphine, epinephrine, adenosine, surgical kit, PAK |

## The bags (`addons/medbags`)

The contents are CBA settings (`jmfsb_medbags_contents*`): ACE kit by default,
ACM's kit when ACM is loaded (`jmfsb_acm` re-defaults all five at preInit).

| Bag | Who may open it | With ACM, holds |
|---|---|---|
| Boo Boo Bag | anyone | pressure bandages, trauma dressings, tourniquets, a chest seal, an NPA, paracetamol |
| Medic Bag | Combat Lifesaver and up | the above in depth, elastic wraps, NCD kits, OPA/NPA, suction bags, SAM splints, pulse oximeter, morphine, Penthrox, naloxone, inhalants, autoinjectors |
| Trauma Kit | Medic | the airway and chest set: i-gel, cric kit, NCD, chest tube, thoracostomy, BVM, IV/IO, stethoscope, surgical kit |
| Fluid Kit | Medic | O- blood, plasma, saline, field transfusion kits, lines, calcium |
| Drug Kit | Medic | the vials (TXA, epinephrine, morphine, fentanyl, ketamine, amiodarone, lidocaine, ondansetron, ertapenem, calcium, atropine, esmolol, adenosine), syringes, fentanyl lozenges |

Every faction unit spawns with a Boo Boo Bag in place of the vanilla first-aid
kit (`faction_jmsb`), so everyone carries the common items.

## The arsenals (TAC//PAC)

Set from `docs/acm/items-by-level.md` (2026-10-09). Each level carries its own
column plus every column to its left; the medic bags sit with the level that
opens them.

- `JMSB.arsenal` (everyone): tourniquet, pressure bandage, elastic wrap,
  paracetamol, body bag, the Boo Boo Bag.
- `JMSB.arsenal.qual_CLS`: emergency trauma dressing, NPA, OPA, suction bag,
  chest seal, NCD kit, pulse oximeter, AED, SAM splint, Penthrox, naloxone,
  ammonia inhalant, the ATNA and midazolam autoinjectors, the Medic Bag.
- `JMSB.arsenal.qual_MEDIC`: the CLS set plus i-gel, CricKit, ACCUVAC, BVM and
  pocket BVM, oxygen, stethoscope, thoracostomy and chest tube kits, pressure
  cuff, 14g/16g IVs, FAST1 and EZ-IO, the four syringes, O- blood in three
  sizes, field transfusion kits, fentanyl lozenge, the thirteen vials; ACE's
  saline, plasma and epinephrine autoinjector; the Trauma, Fluid and Drug kits.
- Gone from every list, per the document: ACE field, packing and elastic
  dressings, QuikClot, splint, morphine and adenosine autoinjectors,
  painkillers, ACE blood bags, the personal aid kit, and ACM's pre-filled
  syringes (the medic draws from vials).
- Not decided there and left as they were: the ACE surgical kit and suture
  (with the Medic).

`ACM_Paracetamol` and `ACM_AmmoniaInhalant` are magazines in ACM's config, so
they sit in the arsenals' `magazines` lists, not `itemsMedical`.

Backups: `D:\Git\_jmsb_db_backup_2026-10-08\pac_before_acm_medical.json`.
