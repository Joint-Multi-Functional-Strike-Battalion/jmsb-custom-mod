#include "script_component.hpp"
/*
 * Author: YonV
 * Fits one vehicle (server): decides what it carries, arms the launchers
 * and the emitter, and starts its watch. A vehicle that carries nothing is
 * left alone - it is still on the registered list, so it is not asked again.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];
if (isNull _veh) exitWith {};

([_veh] call FUNC(fitFor)) params ["_fit", "_rf", "_name"];
if (_fit isEqualTo FIT_NONE && {!_rf}) exitWith {
    if (GVAR(debug)) then { INFO_2("%1 (%2) carries nothing",typeOf _veh,[_veh] call FUNC(tierOf)) };
};

private _charges = if (_fit isEqualTo FIT_NONE) then { 0 } else { (GVAR(fits) get _fit) select 0 };
if (_rf && _name isEqualTo "") then { _name = "RF emitter" };
if (_rf && _fit isNotEqualTo FIT_NONE) then { _name = _name + " + RF" };

// public, so the crew's readout (fnc_report) can read them on their client
_veh setVariable [QGVAR(fit), _fit, true];
_veh setVariable [QGVAR(rf), _rf, true];
_veh setVariable [QGVAR(name), _name, true];
_veh setVariable [QGVAR(ammoL), _charges, true];
_veh setVariable [QGVAR(ammoR), _charges, true];
_veh setVariable [QGVAR(ammoMax), _charges, true];
// server-side working state
_veh setVariable [QGVAR(seen), []];
_veh setVariable [QGVAR(rfReady), 0, true];
_veh setVariable [QGVAR(nextRearm), CBA_missionTime + GVAR(rearmDelay)];
// the guns' own ammunition, watched for a rearm (see fnc_watch)
private _gun = 0;
{ _gun = _gun + (_x select 2) } forEach magazinesAllTurrets _veh;
_veh setVariable [QGVAR(lastAmmo), _gun];
_veh setVariable [QGVAR(canSmoke), true];

private _h = [LINKFUNC(watch), APS_TICK, [_veh]] call CBA_fnc_addPerFrameHandler;
_veh setVariable [QGVAR(pfh), _h];

if (GVAR(debug)) then { INFO_4("%1 fitted: %2 (%3 charges/side), RF %4",typeOf _veh,_fit,_charges,_rf) };
