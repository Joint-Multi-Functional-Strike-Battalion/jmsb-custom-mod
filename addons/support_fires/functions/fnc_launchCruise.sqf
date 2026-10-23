#include "script_component.hpp"
/*
 * Author: JMSB
 * A cruise missile salvo: after the launcher's response time and the DELAY
 * asked for, the missiles leave the launcher a few seconds apart
 * (FUNC(flyCruise) launches and flies each one). The target is marked for the
 * side until the mission ends - when the last missile is gone, on the target,
 * shot down, or out of fuel.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position, ATL <ARRAY>
 * 2: [missiles, delay (s)] <ARRAY>
 * 3: Requester <OBJECT>
 * 4: Mission token <NUMBER>
 * 5: Asset id <STRING>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, _pos, [2, 0], player, 1, "fires:2"] call jmfsb_support_fires_fnc_launchCruise
 *
 * Public: No
 */

params ["_logic", "_target", "_opts", "_requester", "_token", "_assetId"];
_opts params [["_count", 1, [0]], ["_delay", 0, [0]]];

private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
_count = _count min (_logic getVariable [QGVAR(left), 0]);

if (_count < 1) exitWith {
    [_assetId, false, format ["%1: no missiles left", _callsign], _requester] call EFUNC(support,ack);
};

(_logic getVariable [QGVAR(response), [0, 0]]) params [["_respMin", 0], ["_respMax", 0]];
private _wait = _respMin + random (_respMax - _respMin) + (0 max _delay);

_logic setVariable [QGVAR(status), STATUS_INBOUND, true];
_logic setVariable [QGVAR(inFlight), _count];

for "_i" from 0 to (_count - 1) do {
    [{_this call FUNC(flyCruise)}, [_logic, _target, _token], _wait + _i * CM_SALVO_GAP] call CBA_fnc_waitAndExecute;
};

private _eta = _wait + CM_BOOST_TIME + (_logic distance2D _target) / (_logic getVariable [QGVAR(speed), 1]);

[_logic, _target, format ["%1 - CRUISE STRIKE", _callsign]] call FUNC(mark);

if (_wait >= 1) then {
    [QGVAR(say), [_logic, format ["strike received - launch in %1 sec", round _wait], "normal"]] call CBA_fnc_globalEvent;
};

[_assetId, true, format [
    "%1 - %2 missile(s), launch in %3 sec, time to target %4 sec",
    _callsign, _count, round _wait, round _eta
], _requester] call EFUNC(support,ack);
