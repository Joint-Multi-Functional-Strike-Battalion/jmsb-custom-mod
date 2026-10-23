/*
    Author: TheTimidShade
    Description:
        Updates the player skill boxes when a player is selected - what he holds now, permanent and for this mission
    Parameters:
        NONE
    Returns:
        NONE
*/
#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

disableSerialization;

private _admp_display = uiNamespace getVariable ['admp_displayVar', displayNull];
if (isNull _admp_display) exitWith {}; // check display exists

private _admp_playerlist_listbox = _admp_display displayCtrl IDC_ADMINPANEL_PLAYERLIST_LISTBOX;
private _player = [_admp_playerlist_listbox] call admp_fnc_playerFromSelection; // get selected player

// The tags PAC puts on him (jmfsb_pac_skillTags) name the skills he holds;
// the bare variables and traits are what a mission without PAC gives.
private _tags = _player getVariable ["jmfsb_pac_skillTags", []];
if !(_tags isEqualType []) then {_tags = []};
private _medicClass = _player getVariable ["ace_medical_medicClass", parseNumber (_player getUnitTrait "Medic")];
private _engineer = _player getVariable ["ACE_IsEngineer", parseNumber (_player getUnitTrait "Engineer")];
if !(_medicClass isEqualType 0) then {_medicClass = parseNumber _medicClass};
if !(_engineer isEqualType 0) then {_engineer = parseNumber _engineer};

private _held = [
    [IDC_ADMINPANEL_PLAYER_SKILLS_CLS_CHECKBOX, "CLS" in _tags || _medicClass isEqualTo 1],
    [IDC_ADMINPANEL_PLAYER_SKILLS_MED_CHECKBOX, "MED" in _tags || _medicClass > 1],
    [IDC_ADMINPANEL_PLAYER_SKILLS_ENG_CHECKBOX, "ENG" in _tags || _engineer > 0],
    [IDC_ADMINPANEL_PLAYER_SKILLS_EOD_CHECKBOX, "BRC" in _tags || (_player getVariable ["ACE_isEOD", _player getUnitTrait "ExplosiveSpecialist"]) isEqualTo true],
    [IDC_ADMINPANEL_PLAYER_SKILLS_ISR_CHECKBOX, "ISR" in _tags || (_player getVariable ["isISR", false]) isEqualTo true],
    [IDC_ADMINPANEL_PLAYER_SKILLS_JFO_CHECKBOX, "JFO" in _tags || (_player getVariable ["isJFO", false]) isEqualTo true],
    [IDC_ADMINPANEL_PLAYER_SKILLS_UAV_CHECKBOX, "UAV" in _tags || (_player getVariable ["UAVHacker", _player getUnitTrait "UAVHacker"]) isEqualTo true],
    [IDC_ADMINPANEL_PLAYER_SKILLS_MKS_CHECKBOX, "MKS" in _tags],
    [IDC_ADMINPANEL_PLAYER_SKILLS_SNP_CHECKBOX, "SNP" in _tags],
    [IDC_ADMINPANEL_PLAYER_SKILLS_HVY_CHECKBOX, "HVY" in _tags],
    [IDC_ADMINPANEL_PLAYER_SKILLS_RTO_CHECKBOX, "RTO" in _tags || (_player getVariable ["isRTO", false]) isEqualTo true]
];

{
    _x params ["_idc", "_has"];
    (_admp_display displayCtrl _idc) cbSetChecked (!isNull _player && _has);
} forEach _held;
