# Medic

`jmfsb_medic`

TAC//MEDIC: a tablet app and a live tile for the section's CLS and medics. The tile counts the wounded in the player's squad and turns to the inverted accent block the moment anyone is in cardiac arrest or bleeding heavily. The app lists the squad worst first (ARREST, UNCONSCIOUS, WOUNDED, OK, then the dead last, since they are not in the medic's queue) and opens a patient page. That page shows heart rate, blood pressure, SpO2, respiration rate, blood type, blood volume, bleeding, pain, airway, chest (pneumothorax / hemothorax), cardiac rhythm, wounds per body part, tourniquets, fractures and splints, IVs running, and a SHOW ON MAP button.

**Who sees it.** The tile and app are only for a player who is a CLS or a medic. That means his PAC skill tags (`jmfsb_pac_skillTags`) hold `CLS` or `MED`, or the same skills have set ACE's medic class (`ace_medical_medicClass` 1 or 2) or the Medic trait. Nobody else gets a tile, so nobody else gets a way into the app. When a mission gates tiles by role (`tiles[]`), a medic role has to list `medic` there.

**Optional dependencies.** ACE medical and Advanced Combat Medicine (ACM) are both optional. Without ACE medical the tile is stale and the app says MEDICAL SYSTEM NOT LOADED. With ACE but no ACM, the ACE readings work and the ACM-only lines (devices, respiration, airway, chest, rhythm) say ACM NOT LOADED.

## Device-gated vitals

The tablet is itself an EKG and a pulse oximeter (user, 2026-10-22): heart rate, SpO2 and the rhythm are live on every man ACE medical has set up, read from ACE's own values as the tablet's leads. The rest is live only while a device that reads it is on the patient (user default, 2026-10-19), and a placed device wins over the tablet's leads:

| Reading | Live from |
|---|---|
| Heart rate | ACM pulse oximeter on either arm (`ACM_breathing_PulseOximeter_Placement` / `_Display`); else the tablet's EKG (`ace_medical_heartRate`) |
| SpO2 | ACM pulse oximeter, or the AED's pulse oximeter lead (`ACM_circulation_AED_Placement_PulseOximeter` / `AED_PulseOximeter_Display`); else the tablet's pulse ox (`ace_medical_spo2`) |
| Blood pressure | ACM pressure cuff (`ACM_circulation_PressureCuff_Placement`; the value is ACE's synced `ace_medical_bloodPressure`), or the AED NIBP cuff's last cycle (`ACM_circulation_AED_NIBP_Display`) |
| Respiration rate | AED capnograph (`ACM_circulation_AED_Placement_Capnograph` / `AED_RR_Display`) |
| Cardiac rhythm | AED pads (`ACM_circulation_AED_Placement_Pads`; rhythm `ACM_circulation_Cardiac_RhythmState`, 0 sinus, 1 asystole, 2 VF, 3 pulseless VT, 4 VT, 5 PEA) |

Without a device, the line shows the last hand check, with its age and the medic who took it. Hand checks are recorded off ACE's `ace_treatmentSucceded` event on the medic's machine:

- `CheckPulse` records heart rate.
- `CheckBloodPressure` records blood pressure when ACM is absent. Under ACM that action is capillary refill and records nothing.
- `CheckBreathing` (ACM) records respiration rate.

ACM's cuff readings (`MeasureBloodPressure` / `MeasureBloodPressureStethoscope`) are not recorded. Their treatment completes in 0.01 s and only opens ACM's gauge, which the medic can cancel, so `ace_treatmentSucceded` fires before any reading exists. They need the cuff on that arm, and while the cuff is on, the BP line is live anyway.

The reading is taken on the patient's own machine, where his vitals are exact, through the `jmfsb_medic_measure` targeted event. It is published on him as `jmfsb_medic_checkHR` / `_checkBP` / `_checkRR` (`[value, missionTime, medicName]`), so every medic in the section sees the same last reading. A check on a limb under a tourniquet reads zero. There is no hand check for SpO2. With neither a device nor a hand check, the line reads `--` and NOT MONITORED.

Blood type is always shown, because it comes off the dog tags. The app reads `ACM_circulation_BloodType` first (0-7 = O+, O-, A+, A-, B+, B-, AB+, AB-), then ACE's `ace_dogtags_dogtagData`. If neither is set, it calls `ace_dogtags_fnc_getDogtagData`, which works the tag out and publishes it, the same as a hand dog-tag check.

## Locality: what is read, and how fresh it is

Every variable the app reads but one is published by its owner, so a remote patient shows the same lines as the man beside you. How fresh a value is depends on how its owner publishes it:

- **Published on change** (`setVariable ..., true`). These are current within network latency:
  - ACE: `ace_medical_inCardiacArrest`, `ACE_isUnconscious`, `ace_medical_woundBleeding`, `ace_medical_openWounds`, `ace_medical_bandagedWounds`, `ace_medical_tourniquets`, `ace_medical_fractures`, `ace_medical_inPain`, `ace_medical_hemorrhage`.
  - ACM: the pulse oximeter display (refreshed every second while it is on), the pressure-cuff and AED placements and displays, `ACM_circulation_BloodType`, `ACM_circulation_Cardiac_RhythmState`, `ACM_disability_SplintStatus` (0 none, 1 SAM splint, 2 wrapped), the airway states (`ACM_airway_AirwayObstructionVomit_State`, `_AirwayObstructionBlood_State`, `_AirwayCollapse_State`, `_AirwayItem_Oral`, `_AirwayItem_Nasal`, `_SurgicalAirway_State`), and the chest states (`ACM_breathing_Pneumothorax_State`, `_TensionPneumothorax_State`, `_Hemothorax_State`, `_ChestSeal_State`).
- **Synced on the ACE vitals cadence** (every 10-20 s under ACM): `ace_medical_heartRate`, `ace_medical_bloodPressure`, `ace_medical_bloodVolume`, `ACM_breathing_RespirationRate`, and the IV bags (`ace_medical_ivBags`, `ACM_circulation_IV_Bags`). On a remote patient these are up to about 20 s old. For that reason a hand check is read on the patient's machine and not on the medic's. The live cuff line, the BLOOD column and the IV RUNNING volumes are this synced value. ACE's `ace_medical_spo2` is not read; SpO2 comes only from the ACM device displays.
- **Local only**: `ace_medical_pain`. ACE sets the pain level without publishing it. The PAIN line shows the level (NONE / MILD / MODERATE / SEVERE) only for a local patient, such as the player himself. A remote patient shows ACE's published `ace_medical_inPain` flag as IN PAIN or NONE, with the note LEVEL LOCAL ONLY. The state sort counts a man as hurt from that flag too.

The bleed grade (SLOW / MODERATE / SEVERE / MASSIVE, with SEVERE and above counting as "bleeding heavily") follows ACE's own medical menu and ACM's copy of it (`ACM_core_fnc_getBleedSeverity`). It compares the blood-loss rate, not the raw wound bleeding, against half the cardiac output, stepped at a tenth, a half and the whole of it. Blood loss comes from `ace_medical_status_fnc_getBloodLoss`, which ACM overrides, so with ACM loaded the grade is ACM's own. Without that function it is wound bleeding x cardiac output x `ace_medical_bleedingCoefficient`. Cardiac output comes from `ace_medical_status_fnc_getCardiacOutput` when it is loaded. A heavy bleeder sorts with cardiac arrest at the top of the list.

The variable names are ACE's public unit variables. For ACM they were read from the ACM 1.4.8 source (circulation, breathing, airway, disability, core), including its compiled functions for the macro-built names and enums. All of them are listed once, in `script_component.hpp`.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_tacpad`
- `jmfsb_tacpad_apps`
- `cba_xeh` _(external)_

## Ships

16 functions.

## Functions

<details><summary>16</summary>

- `jmfsb_medic_fnc_age`
- `jmfsb_medic_fnc_app`
- `jmfsb_medic_fnc_appList`
- `jmfsb_medic_fnc_appNotice`
- `jmfsb_medic_fnc_appPatient`
- `jmfsb_medic_fnc_bloodType`
- `jmfsb_medic_fnc_isMedic`
- `jmfsb_medic_fnc_measureLocal`
- `jmfsb_medic_fnc_nameOf`
- `jmfsb_medic_fnc_patientState`
- `jmfsb_medic_fnc_readBody`
- `jmfsb_medic_fnc_readStatus`
- `jmfsb_medic_fnc_readVitals`
- `jmfsb_medic_fnc_recordCheck`
- `jmfsb_medic_fnc_showOnMap`
- `jmfsb_medic_fnc_tile`

</details>
