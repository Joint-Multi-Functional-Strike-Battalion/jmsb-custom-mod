#include "script_component.hpp"

// A manual reading is taken where the patient is local, because that is the
// only place his vitals are exact: the server sends it there by remoteExec
// (FUNC(srvMeasure) -> FUNC(measureLocal)) - no CBA event (review R1).

if (!hasInterface) exitWith {};

// A medic's hand check, heard on the medic's own machine. ACE raises it after
// every treatment - the misspelling is ACE's. Without ACE it never fires.
["ace_treatmentSucceded", LINKFUNC(recordCheck)] call CBA_fnc_addEventHandler;

// The MEDIC tile opens this - see EFUNC(tacpad_apps,tileData).
[APP_ID, FUNC(app)] call EFUNC(tacpad,registerApp);

// ---- the watch HUD's medical profile (docs/DESIGN_WATCH_HUD.json) ----------------
// Anyone in AiTR goggles (decided 2026-11-07): the action key (numpad 9) on
// any man within WATCH_REACH adds him; the panel draws beside him and on the
// device. jmfsb_watch keeps the slots, the keys and the clearing.
if (!isNil QEFUNC(watch,register)) then {
    [WATCH_PROFILE, createHashMapFromArray [
        ["name", "Medical"], ["icon", AITR_ICON], ["slots", WATCH_SLOTS], ["order", WATCH_ORDER],
        ["gate", {[] call FUNC(aitrOn)}],
        ["accepts", {params ["_target"]; _target isKindOf "CAManBase" && {(player distance _target) <= WATCH_REACH}}],
        ["row", FUNC(watchRow)],
        ["trace", FUNC(watchTrace)],
        ["hud", true], ["hudOn", {[] call FUNC(aitrOn)}],
        ["report", FUNC(watchReport)],
        // SHARE (F2): the patient onto every medic within reach
        ["share", {params ["_target"]; [WATCH_PROFILE, _target, {params ["_unit"]; [_unit] call FUNC(isMedic)}] call EFUNC(watch,slotShare)}],
        ["alert", FUNC(watchAlerts)],
        // SET TRIAGE: ACE's own card, so the medical menu, the vehicle list
        // and the HUD read one triage; the override sticks until changed
        ["actions", [
            ["Triage T1 immediate", {params ["_t"]; [_t, 1] call ace_medical_treatment_fnc_setTriageStatus}],
            ["Triage T2 delayed", {params ["_t"]; [_t, 2] call ace_medical_treatment_fnc_setTriageStatus}],
            ["Triage T3 minimal", {params ["_t"]; [_t, 3] call ace_medical_treatment_fnc_setTriageStatus}],
            ["Triage T4 expectant", {params ["_t"]; [_t, 4] call ace_medical_treatment_fnc_setTriageStatus}],
            ["Triage clear", {params ["_t"]; [_t, 0] call ace_medical_treatment_fnc_setTriageStatus}]
        ]]
    ]] call EFUNC(watch,register);

    // ACE interaction on a man too: watch or unwatch his vitals.
    if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
        private _action = [
            QGVAR(watchShow), "Show vitals (AiTR)", AITR_ICON,
            {[WATCH_PROFILE, _target] call EFUNC(watch,toggle)},
            {_target isNotEqualTo _player && {[] call FUNC(aitrOn)}},
            {}, [], [0, 0, 0], WATCH_REACH, [false, false, false, false, false],
            {
                params ["_target", "", "", "_actionData"];
                private _on = ((EGVAR(watch,slots) getOrDefault [WATCH_PROFILE, []]) findIf {(_x # 0) isEqualTo _target}) >= 0;
                _actionData set [1, ["Show vitals (AiTR)", "Hide vitals (AiTR)"] select _on];
            }
        ] call ace_interact_menu_fnc_createAction;
        ["CAManBase", 0, ["ACE_MainActions"], _action, true] call ace_interact_menu_fnc_addActionToClass;
    };
};
