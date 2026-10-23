#define COMPONENT medic
#define COMPONENT_BEAUTIFIED Medic
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_MEDIC
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_MEDIC
    #define DEBUG_SETTINGS DEBUG_SETTINGS_MEDIC
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The tacpad's drawing grammar - host rectangle, row height, padding, rule
// weights - so the MEDIC app is drawn in the same hand as every other app.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// ---------------------------------------------------------------------------
// THE APP
// ---------------------------------------------------------------------------
#define APP_ID "medic"
#define APP_W 0.66
#define APP_H 0.74

// Seconds between redraws while the app is open. A patient page is a monitor;
// one that does not move is a photograph of one.
#define MEDIC_REFRESH 1

// The map control on the host display, and the control type to look for when a
// device host puts its map somewhere else (CT_MAP_MAIN).
#define MAP_IDC 51
#define MAP_CTRL_TYPE 101
#define MAP_ANIM_TIME 0.3

// ---------------------------------------------------------------------------
// WHO IS A MEDIC. The PAC skill abbreviations a CLS or a medic carries
// (jmfsb_pac_skillTags - see EFUNC(pac,applySkills)). The same skills set ACE's
// medic class (CLS 1, Medic 2 - addons/acm/README.md), which is the fallback.
// ---------------------------------------------------------------------------
#define MEDIC_TAGS ["CLS", "MED", "MEDIC"]

// ---------------------------------------------------------------------------
// PATIENT STATES, worst first - the order the list is sorted in. DEAD is last
// on purpose: the list is the medic's work queue and a dead man is not on it.
// ---------------------------------------------------------------------------
#define STATE_ARREST 0
#define STATE_UNCON 1
#define STATE_WOUNDED 2
#define STATE_OK 3
#define STATE_DEAD 4
#define STATE_WORDS ["ARREST", "UNCONSCIOUS", "WOUNDED", "OK", "DEAD"]

// ---------------------------------------------------------------------------
// BLEEDING, the way ACE's own medical menu grades it (and ACM's copy of it,
// ACM_core_fnc_getBleedSeverity): the BLOOD LOSS rate - wound bleeding times
// cardiac output times ACE's bleeding coefficient - against the knock-out rate
// (half the cardiac output), stepped at a tenth, a half and the whole of it.
// SEVERE and MASSIVE are "bleeding heavily".
// ---------------------------------------------------------------------------
#define BLEED_KNOCKOUT 0.5
#define BLEED_STEPS [0.1, 0.5, 1]
#define BLEED_WORDS ["SLOW", "MODERATE", "SEVERE", "MASSIVE"]
#define BLEED_HEAVY 2
// Cardiac output in l/s: a floor so an arrested heart does not make every
// trickle read MASSIVE, and the resting value when ACE's function is absent.
#define CARDIAC_OUTPUT_FLOOR 0.05
#define CARDIAC_OUTPUT_NOMINAL 0.0875

// Pain (ace_medical_pain, 0-1) in words, stepped at these. The level is local
// to the patient's machine; a remote patient shows only ACE's published
// in-pain flag (ace_medical_inPain), as IN PAIN or NONE.
#define PAIN_STEPS [0.1, 0.4, 0.7]
#define PAIN_WORDS ["NONE", "MILD", "MODERATE", "SEVERE"]
#define PAIN_REMOTE_WORDS ["NONE", "IN PAIN"]

// Hemorrhage class (ace_medical_hemorrhage, 0-4) at which blood volume is hot.
#define HEMORRHAGE_HOT 2
#define BLOOD_VOLUME_FULL 6

// ---------------------------------------------------------------------------
// BODY PARTS, in ACE's order. The ACM device arrays (pulse oximeter, pressure
// cuff) hold the two arms only, so their index is the part index minus this.
// ---------------------------------------------------------------------------
#define BODY_PARTS ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"]
#define BODY_LABELS ["HEAD", "TORSO", "L ARM", "R ARM", "L LEG", "R LEG"]
#define ARM_OFFSET 2

// ACM's enums, read out of ACM 1.4.8 (convertBloodType, AED_AnalyzeRhythm).
#define BLOOD_TYPES ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"]
#define RHYTHM_SINUS 0
#define RHYTHMS ["SINUS", "ASYSTOLE", "VF", "PULSELESS VT", "VT", "PEA"]
// ACM_disability_SplintStatus per part: none, SAM splint on, SAM splint wrapped.
#define SPLINT_NONE 0
#define SPLINT_WRAPPED 2
// ace_medical_fractures per part: an unset fracture, and one set / splinted.
#define FRACTURE_UNSET 1
#define FRACTURE_SET -1

// The treatments a manual measurement is taken from (ace_treatmentSucceded).
// With ACM loaded, CheckBloodPressure is its capillary refill and records
// nothing; without it, it is ACE's BP check. ACM's own cuff readings
// (MeasureBloodPressure*) are not recorded: their treatment "succeeds" before
// the medic has read the gauge, or even if he cancels it - and the cuff they
// need is on the arm, so the BP line is live while it is.
#define CHECK_PULSE "CheckPulse"
#define CHECK_BP_ACE "CheckBloodPressure"
#define CHECK_BREATHING "CheckBreathing"
#define CHECK_KINDS ["hr", "bp", "rr"]
#define CHECK_VARS [QGVAR(checkHR), QGVAR(checkBP), QGVAR(checkRR)]

// ---------------------------------------------------------------------------
// THE NAMES READ OFF OTHER MODS, in one place. Every one of these but the pain
// level is published by its owner (setVariable ..., true, or the ACE vitals
// sync) - see README.
// ---------------------------------------------------------------------------
// ACE medical (ace_medical_status / ace_medical_vitals unit variables)
#define ACEV_HEART_RATE "ace_medical_heartRate"
#define ACEV_SPO2 "ace_medical_spo2"
#define ACEV_BLOOD_PRESSURE "ace_medical_bloodPressure"
#define ACEV_BLOOD_VOLUME "ace_medical_bloodVolume"
#define ACEV_HEMORRHAGE "ace_medical_hemorrhage"
#define ACEV_PAIN "ace_medical_pain"
#define ACEV_IN_PAIN "ace_medical_inPain"
#define ACEV_BLEEDING_COEF "ace_medical_bleedingCoefficient"
#define ACEV_WOUND_BLEEDING "ace_medical_woundBleeding"
#define ACEV_OPEN_WOUNDS "ace_medical_openWounds"
#define ACEV_BANDAGED_WOUNDS "ace_medical_bandagedWounds"
#define ACEV_TOURNIQUETS "ace_medical_tourniquets"
#define ACEV_FRACTURES "ace_medical_fractures"
#define ACEV_IV_BAGS "ace_medical_ivBags"
#define ACEV_CARDIAC_ARREST "ace_medical_inCardiacArrest"
#define ACEV_UNCONSCIOUS "ACE_isUnconscious"
#define ACEV_MEDIC_CLASS "ace_medical_medicClass"
#define ACEV_DOGTAG_DATA "ace_dogtags_dogtagData"

// Advanced Combat Medicine
#define ACMV_BLOOD_TYPE "ACM_circulation_BloodType"
#define ACMV_RESP_RATE "ACM_breathing_RespirationRate"
#define ACMV_PULSEOX "ACM_breathing_PulseOximeter_Placement"
#define ACMV_PULSEOX_DISPLAY "ACM_breathing_PulseOximeter_Display"
#define ACMV_CUFF "ACM_circulation_PressureCuff_Placement"
#define ACMV_AED_PADS "ACM_circulation_AED_Placement_Pads"
#define ACMV_AED_PULSEOX "ACM_circulation_AED_Placement_PulseOximeter"
#define ACMV_AED_SPO2 "ACM_circulation_AED_PulseOximeter_Display"
#define ACMV_AED_CUFF "ACM_circulation_AED_Placement_PressureCuff"
#define ACMV_AED_NIBP "ACM_circulation_AED_NIBP_Display"
#define ACMV_AED_CAPNO "ACM_circulation_AED_Placement_Capnograph"
#define ACMV_AED_RR "ACM_circulation_AED_RR_Display"
#define ACMV_RHYTHM "ACM_circulation_Cardiac_RhythmState"
#define ACMV_IV_BAGS "ACM_circulation_IV_Bags"
#define ACMV_SPLINTS "ACM_disability_SplintStatus"
#define ACMV_VOMIT "ACM_airway_AirwayObstructionVomit_State"
#define ACMV_BLOOD_AIRWAY "ACM_airway_AirwayObstructionBlood_State"
#define ACMV_COLLAPSE "ACM_airway_AirwayCollapse_State"
#define ACMV_ORAL "ACM_airway_AirwayItem_Oral"
#define ACMV_NASAL "ACM_airway_AirwayItem_Nasal"
#define ACMV_SURGICAL "ACM_airway_SurgicalAirway_State"
#define ACMV_PTX "ACM_breathing_Pneumothorax_State"
#define ACMV_TPTX "ACM_breathing_TensionPneumothorax_State"
#define ACMV_HTX "ACM_breathing_Hemothorax_State"
#define ACMV_CHEST_SEAL "ACM_breathing_ChestSeal_State"
