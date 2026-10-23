#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads one JMSB - Loitering Munitions module: a launch site at the module's
 * position with a stock of munitions.
 *
 * THE SWITCHBLADE WHEN IT IS THERE. A blank class is the Switchblade 600 when
 * the Switchblade mod is loaded (CfgPatches "switchblade") and the side's
 * Darter otherwise, flown as a one-way attack drone. The Switchblade carries
 * no warhead in config - its own Killed handler spawns one - so the warhead is
 * this module's to name, and blank picks the mod's own to match.
 *
 * ITS RANGE IS ITS TRANSIT TIME. A munition that has not reached the area in
 * LM_TRANSIT_MAX seconds is lost, so a target further than the airframe flies
 * in that time at its transit speed is refused (FUNC(task)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, [], true] call jmfsb_support_fires_fnc_moduleLoiter
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], "", ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};
if (_logic in GVAR(entities)) exitWith {};

private _callsign = _logic getVariable ["callsign", ""];
private _side = (call EFUNC(common,playerSides)) param [0, west];

private _cls = _logic getVariable ["munitionClass", ""];
if (_cls isEqualTo "") then {
    _cls = if (isClass (configFile >> "CfgPatches" >> SWB_PATCH)) then {
        [SWB_WEST, SWB_GUER] select (_side isEqualTo independent)
    } else {
        switch (_side) do {
            case east: {LM_FALLBACK_EAST};
            case independent: {LM_FALLBACK_GUER};
            default {LM_FALLBACK_WEST};
        }
    };
};
if !(isClass (configFile >> "CfgVehicles" >> _cls) && {_cls isKindOf "Air"}) exitWith {
    WARNING_2("Loitering Munitions '%1': '%2' is not an air vehicle class - no asset placed",_callsign,_cls);
};

private _warhead = _logic getVariable ["warhead", ""];
if (_warhead isEqualTo "" || {!isClass (configFile >> "CfgAmmo" >> _warhead)}) then {
    if (_warhead isNotEqualTo "") then {
        WARNING_2("Loitering Munitions '%1': warhead '%2' is not a CfgAmmo class - the default is used",_callsign,_warhead);
    };
    _warhead = switch (true) do {
        case ("SwitchBlade_300" in _cls): {SWB_HE_WARHEAD};
        case ("SwitchBlade" in _cls): {SWB_AT_WARHEAD};
        default {LM_WARHEAD_DEF};
    };
};

_logic setVariable [QGVAR(cls), _cls, true];
_logic setVariable [QGVAR(warhead), _warhead, true];
_logic setVariable [QGVAR(left), 0 max round (_logic getVariable ["munitions", 6]), true];
_logic setVariable [QGVAR(salvo), 1 max round (_logic getVariable ["launchSize", 2]), true];
_logic setVariable [QGVAR(loiterTime), 30 max (_logic getVariable ["loiterTime", 300]), true];
_logic setVariable [QGVAR(rule), (RULE_BOTH max round (_logic getVariable ["strikeRules", RULE_BOTH])) min RULE_INFANTRY, true];
_logic setVariable [QGVAR(altitude), 30 max (_logic getVariable ["altitude", 150]), true];
_logic setVariable [QGVAR(cooldown), 0 max (_logic getVariable ["cooldown", 60]), true];
private _transit = LM_CRUISE_SHARE * (getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed")) / 3.6;
_logic setVariable [QGVAR(reach), [1e7, LM_TRANSIT_MAX * _transit] select (_transit > 0), true];

[_logic, TYPE_LOITER, _callsign, "GHOST"] call FUNC(register);
