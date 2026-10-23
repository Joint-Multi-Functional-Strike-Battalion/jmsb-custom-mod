#include "script_component.hpp"
/*
 * Author: JMSB
 * A loitering munition launch: the munitions leave the site a few seconds
 * apart (FUNC(loiterOne)). The mission ends when the last of them is gone -
 * on a target, shot down, self-destructed or recalled.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position, ATL <ARRAY>
 * 2: [munitions, search radius (m)] <ARRAY>
 * 3: Requester <OBJECT>
 * 4: Mission token <NUMBER>
 * 5: Asset id <STRING>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, _pos, [2, 400], player, 1, "fires:3"] call jmfsb_support_fires_fnc_launchLoiter
 *
 * Public: No
 */

params ["_logic", "_target", "_opts", "_requester", "_token", "_assetId"];
_opts params [["_count", 1, [0]], ["_radius", SEARCH_MIN, [0]]];

private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
_count = _count min (_logic getVariable [QGVAR(left), 0]);

if (_count < 1) exitWith {
    [_assetId, false, format ["%1: no munitions left", _callsign], _requester] call EFUNC(support,ack);
};

_logic setVariable [QGVAR(status), STATUS_INBOUND, true];
_logic setVariable [QGVAR(inFlight), _count];

// The prey is always the enemy side, worked out from the mission's side
// relations (D59) - never a field on the module.
private _enemy = call EFUNC(common,enemySide);

for "_i" from 0 to (_count - 1) do {
    [{_this call FUNC(loiterOne)}, [_logic, _target, _radius, _enemy, _token], _i * LM_LAUNCH_GAP] call CBA_fnc_waitAndExecute;
};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _cruise = (getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed")) / 3.6 * LM_CRUISE_SHARE;
private _eta = (_logic distance2D _target) / (_cruise max 1);

[_logic, _target, format ["%1 - HUNT", _logic getVariable [QGVAR(callsign), "FIRES"]], _radius] call FUNC(mark);

[_assetId, true, format [
    "%1 - %2 munition(s) launched, on station in about %3 sec",
    _callsign, _count, round _eta
], _requester] call EFUNC(support,ack);
