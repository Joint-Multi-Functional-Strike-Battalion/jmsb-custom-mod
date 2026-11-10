#include "script_component.hpp"
/*
 * Author: YonV
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
 * 6: The wait before the first missile (s), -1 to draw it as above <NUMBER> (optional, default -1) -
 *    a call for fire by message works it out itself (FUNC(threadStrike), 2026-11-01)
 *
 * Each launch is numbered (QGVAR(launchNo)), so its SHOT and SPLASH are
 * called once even when a call for fire's REPEAT launches again on the same
 * mission.
 *
 * Return Value: None
 *
 * Example:
 * [_logic, _pos, [2, 0], player, 1, "fires:2"] call jmfsb_support_fires_fnc_launchCruise
 *
 * Public: No
 */

params ["_logic", "_target", "_opts", "_requester", "_token", "_assetId", ["_exactWait", -1, [0]]];
_opts params [["_count", 1, [0]], ["_delay", 0, [0]]];

private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
_count = _count min (_logic getVariable [QGVAR(left), 0]);

if (_count < 1) exitWith {
    [_assetId, false, format ["%1: no missiles left", _callsign], _requester] call EFUNC(support,ack);
};

(_logic getVariable [QGVAR(response), [0, 0]]) params [["_respMin", 0], ["_respMax", 0]];
private _wait = _respMin + random (_respMax - _respMin) + (0 max _delay);
if (_exactWait >= 0) then {_wait = _exactWait};

_logic setVariable [QGVAR(status), STATUS_INBOUND, true];
_logic setVariable [QGVAR(inFlight), _count];
private _launch = (_logic getVariable [QGVAR(launchNo), 0]) + 1;
_logic setVariable [QGVAR(launchNo), _launch];

for "_i" from 0 to (_count - 1) do {
    [{_this call FUNC(flyCruise)}, [_logic, _target, _token, _launch], _wait + _i * CM_SALVO_GAP] call CBA_fnc_waitAndExecute;
};

private _eta = _wait + CM_BOOST_TIME + (_logic distance2D _target) / (_logic getVariable [QGVAR(speed), 1]);

[_logic, _target, format ["%1 - CRUISE STRIKE", _callsign]] call FUNC(mark);

if (_wait >= 1) then {
    [_logic, format ["strike received - launch in %1 sec", round _wait], "normal"] call FUNC(say);
};

[_assetId, true, format [
    "%1 - %2 missile(s), launch in %3 sec, time to target %4 sec",
    _callsign, _count, round _wait, round _eta
], _requester] call EFUNC(support,ack);

// ON TASK in the asset's thread, if one was filed to it (2026-11-01) - the
// one it launches for when a call for fire tasked it.
[_assetId, "IN_PROGRESS", "", _callsign, false, _logic getVariable [QGVAR(thread), ""]] call EFUNC(support,state);
