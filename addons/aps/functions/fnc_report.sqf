#include "script_component.hpp"
/*
 * Author: YonV
 * The crew's readout (client): the system's name, its charges by side, and
 * where the last round came from as a clock bearing off the turret. Only
 * the people IN the vehicle see it.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Relative bearing of the round, degrees, -1 for none <NUMBER>
 * 2: What happened - "INTERCEPT", "REARMED", "RF BURST" <STRING>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_rel", -1, [0]], ["_what", "", [""]]];
if (!hasInterface || {isNull _veh} || {vehicle player != _veh}) exitWith {};

// the HUD's APS tile shows the last thing the system did for a few seconds
GVAR(lastEvent) = [_what, _rel, CBA_missionTime];

private _name = _veh getVariable [QGVAR(name), "APS"];
private _max = _veh getVariable [QGVAR(ammoMax), 0];
private _lines = [];   // the vehicle name is the notification heading, not a line
if (_max > 0) then {
    _lines pushBack format ["L %1/%2   R %3/%4", _veh getVariable [QGVAR(ammoL), 0], _max, _veh getVariable [QGVAR(ammoR), 0], _max];
};
if (_rel >= 0) then {
    private _clock = round (_rel / 30) mod 12;
    if (_clock == 0) then { _clock = 12 };
    _lines pushBack format ["<t color='#ff8800'>%1 - %2 o'clock</t>", _what, _clock];
} else {
    if (_what isNotEqualTo "") then { _lines pushBack format ["<t color='#ff8800'>%1</t>", _what] };
};
[_name, _lines joinString "<br/>", [0.871, 0.361, 0.188, 1]] call EFUNC(notify,notify);
if (_what isEqualTo "INTERCEPT") then { playSound "Alarm" };
