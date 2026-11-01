#include "script_component.hpp"
params [
    ["_unit",objNull,[objNull]],
    ["_corpse",objNull,[objNull]]
];

// ACE medical and ACM are not required by this addon, so each reset runs
// only when its mod is loaded - a missing one threw and stopped the re-slot.
if (!isNil "ace_medical_treatment_fnc_fullHeal") then {
    [_unit, _unit] call ace_medical_treatment_fnc_fullHeal;
};
{
    if (!isNil _x) then {
        [_unit] call (missionNamespace getVariable _x);
    };
} forEach [
    "ACM_core_fnc_resetVariables",
    "ACM_airway_fnc_resetVariables",
    "ACM_breathing_fnc_resetVariables",
    "ACM_circulation_fnc_resetVariables",
    "ACM_damage_fnc_resetVariables",
    "ACM_disability_fnc_resetVariables"
];
["Respawn", "You have been REZED, praise ArmA.", NOTE_GOOD] call JMFSBFUNC(notify,notify);

private _oldPath = [];
private _oldRole = "";

{
    _x params ["","_roles","","","_units"];
    private _groupIndex = _forEachIndex;
    {
        if (_x isEqualTo _corpse) exitWith {
            _oldPath = [_groupIndex,_forEachIndex];
            _oldRole = _roles select _forEachIndex;
        };
    } forEach _units;
} forEach YMF_dynamicGroups;

if (_oldPath isEqualTo []) exitWith {[] call jmfsb_groups_fnc_initGroupMenu};

[_unit,_oldPath,_oldRole,true] remoteExecCall ["jmfsb_groups_fnc_assignPlayer",2];
