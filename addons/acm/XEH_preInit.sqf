#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// ---- ACM's treatments, set to JMSB's two tiers ----------------------------
// WHO MAY DO WHAT when ACM is loaded (Advanced Combat Medicine, D:\work\acm,
// wiki https://bluetheking.github.io/ACM-wiki/en/Overview). Two tiers, the two
// PAC medical skills: CLS (ACE medic class 1) and Medic (class 2, everything
// CLS has and more). ACM ships most of these at Anyone or Medics; these are
// only the DEFAULTS - a server, mission or player value still wins, and every
// one stays in ACM's own settings menu.
//
// Not here because nothing in ACM gates them: pressure bandage, ETD,
// tourniquet, chest seal, pulse oximeter, CPR, SAM splint, paracetamol,
// Penthrox, naloxone - everyone can use them. ACE's own medicIV,
// medicEpinephrine, medicSurgicalKit and the rest are not re-defaulted either:
// jmfsb_cba_settings FORCES them, and a forced value beats any default.
{
    _x params ["_setting", "_level"];
    [_setting, _level] call FUNC(setDefault);
} forEach [
    // airway
    ["ACM_airway_allowOPA", SKILL_CLS],
    ["ACM_airway_allowNPA", SKILL_CLS],
    ["ACM_airway_allowSuctionBag", SKILL_CLS],
    ["ACM_airway_allowSGA", SKILL_MEDIC],                   // i-gel
    ["ACM_airway_allowACCUVAC", SKILL_MEDIC],
    ["ACM_airway_allowSurgicalAirway", SKILL_MEDIC],
    // breathing
    ["ACM_breathing_allowInspectChest", SKILL_CLS],
    ["ACM_breathing_allowNCD", SKILL_CLS],
    ["ACM_breathing_allowThoracostomy", SKILL_MEDIC],
    // circulation
    ["ACM_circulation_allowAED", SKILL_CLS],                // auto mode is a CLS tool
    ["ACM_circulation_allowIV", SKILL_MEDIC],
    ["ACM_circulation_allowIO", SKILL_MEDIC],
    ["ACM_circulation_allowSyringe", SKILL_MEDIC],          // every drawn-up liquid medication
    ["ACM_circulation_allowAmmoniaInhalant", SKILL_CLS],
    ["ACM_circulation_allowFentanylLozenge", SKILL_MEDIC],
    // CBRN
    ["ACM_cbrn_allowATNAAutoinjector", SKILL_CLS],
    ["ACM_cbrn_allowMidazolamAutoinjector", SKILL_CLS],
    // bleeding, fractures, evacuation
    ["ACM_core_allowWrap", SKILL_CLS],
    ["ACM_disability_allowInspectForFracture", SKILL_CLS],
    ["ACM_disability_allowFractureRealignment", SKILL_MEDIC],
    ["ACM_evacuation_allowConvert", SKILL_MEDIC]
];

// ---- the med bags, filled with ACM's kit ----------------------------------
// The same five bags, the same order rule (front of the list is what a man
// with no room keeps), ACM's items in place of ACE's. Each bag is pitched at
// who opens it: the Boo Boo Bag is anyone's self-aid, the Medic Bag a CLS
// load, the Trauma Kit, Fluid Kit and Drug Kit the Medic's. O- is the
// universal donor, so the blood is O-. The levels follow docs/acm/items-by-level.md
// (2026-10-09): the Boo Boo Bag is the self-aid column, the Medic Bag the CLS
// column, and the morphine autoinjector is not issued at all.
{
    _x params ["_setting", "_contents"];
    [_setting, _contents] call FUNC(setDefault);
} forEach [
    ["jmfsb_medbags_contentsFirstAid",
        "ACM_PressureBandage:6, ACM_ElasticWrap:2, ACE_tourniquet:2, ACM_Paracetamol:1, ACE_EarPlugs:1"],
    ["jmfsb_medbags_contentsMedicKit",
        "ACM_PressureBandage:18, ACM_EmergencyTraumaDressing:8, ACM_ElasticWrap:14, ACE_tourniquet:8, ACM_ChestSeal:4, ACM_NCDKit:2, ACM_NPA:4, ACM_OPA:4, ACM_SuctionBag:2, ACM_SAMSplint:6, ACM_PulseOximeter:1, ACM_AED:1, ACM_Inhaler_Penthrox:2, ACM_Paracetamol:4, ACM_Spray_Naloxone:2, ACM_AmmoniaInhalant:2, ACM_Autoinjector_ATNA:3, ACM_Autoinjector_Midazolam:1, ACE_EarPlugs:2"],
    ["jmfsb_medbags_contentsTrauma",
        "ACM_PressureBandage:28, ACM_EmergencyTraumaDressing:12, ACM_ElasticWrap:24, ACE_tourniquet:12, ACM_ChestSeal:8, ACM_NCDKit:4, ACM_ThoracostomyKit:2, ACM_ChestTubeKit:2, ACM_IGel:4, ACM_CricKit:2, ACM_SuctionBag:4, ACM_SAMSplint:12, ACM_IV_16g:8, ACM_IV_14g:4, ACM_IO_FAST:4, ACM_IO_EZ:2, ACM_Stethoscope:1, ACM_PulseOximeter:1, ACM_PocketBVM:1, ACE_surgicalKit:1, ACE_EarPlugs:2"],
    ["jmfsb_medbags_contentsFluid",
        "ACM_BloodBag_ON_500:8, ACE_plasmaIV_500:8, ACE_salineIV_500:8, ACM_FieldBloodTransfusionKit_500:2, ACM_IV_16g:6, ACM_IO_FAST:2, ACM_Vial_CalciumChloride:4, ACM_Syringe_10:4"],
    ["jmfsb_medbags_contentsDrugKit",
        "ACM_Vial_TXA:6, ACM_Vial_Epinephrine:4, ACM_Vial_Morphine:4, ACM_Vial_Fentanyl:4, ACM_Vial_Ketamine:4, ACM_Vial_Amiodarone:4, ACM_Vial_Lidocaine:4, ACM_Vial_Ondansetron:4, ACM_Vial_Ertapenem:4, ACM_Vial_CalciumChloride:4, ACM_Vial_Atropine:2, ACM_Vial_Esmolol:2, ACM_Vial_Adenosine:2, ACM_Syringe_1:4, ACM_Syringe_3:6, ACM_Syringe_5:6, ACM_Syringe_10:4, ACM_Lozenge_Fentanyl:2, ACE_epinephrine:2"]
];

ADDON = true;
