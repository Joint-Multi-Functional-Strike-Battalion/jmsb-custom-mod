/*
    Author: YonV
    Description:
        Writes each skill's name beside its box - TAC//PAC's own name for it
        when PAC is loaded (jmfsb_pac_structure), the panel's words otherwise -
        then loads the selected player's skills into the boxes.
        (user, 2026-10-08: "type out the name of each skill")
    Parameters:
        NONE
    Returns:
        NOTHING
*/
#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

disableSerialization;

private _admp_display = uiNamespace getVariable ['admp_displayVar', displayNull];
if (isNull _admp_display) exitWith {}; // check display exists

private _structure = missionNamespace getVariable ["jmfsb_pac_structure", createHashMap];
if !(_structure isEqualType createHashMap) then {_structure = createHashMap};
private _skills = _structure getOrDefault ["skills", createHashMap];
if !(_skills isEqualType createHashMap) then {_skills = createHashMap};

{
    _x params ["_idc", "_id", "_fallback"];
    private _item = _skills getOrDefault [_id, createHashMap];
    private _name = if (_item isEqualType createHashMap) then {_item getOrDefault ["name", _fallback]} else {_fallback};
    if (!(_name isEqualType "") || _name isEqualTo "") then {_name = _fallback};
    (_admp_display displayCtrl _idc) ctrlSetStructuredText parseText format ["<t font='RobotoCondensed' size='0.7'>%1</t>", _name];
} forEach [
    [IDC_ADMINPANEL_PLAYER_SKILLS_CLS_LABEL, "cls", "Combat Lifesaver"],
    [IDC_ADMINPANEL_PLAYER_SKILLS_MED_LABEL, "medic", "Medic"],
    [IDC_ADMINPANEL_PLAYER_SKILLS_ENG_LABEL, "eng", "Engineer"],
    [IDC_ADMINPANEL_PLAYER_SKILLS_EOD_LABEL, "breacher", "Breacher / EOD"],
    [IDC_ADMINPANEL_PLAYER_SKILLS_ISR_LABEL, "isr", "ISR"],
    [IDC_ADMINPANEL_PLAYER_SKILLS_JFO_LABEL, "jfo", "JFO"],
    [IDC_ADMINPANEL_PLAYER_SKILLS_UAV_LABEL, "uav", "UAV operator"],
    [IDC_ADMINPANEL_PLAYER_SKILLS_MKS_LABEL, "marksman", "Marksman"],
    [IDC_ADMINPANEL_PLAYER_SKILLS_SNP_LABEL, "sniper", "Sniper"],
    [IDC_ADMINPANEL_PLAYER_SKILLS_HVY_LABEL, "heavy", "Heavy Weapons"],
    [IDC_ADMINPANEL_PLAYER_SKILLS_RTO_LABEL, "rto", "RTO"]
];

[] call admp_fnc_loadPlayerSkills;
