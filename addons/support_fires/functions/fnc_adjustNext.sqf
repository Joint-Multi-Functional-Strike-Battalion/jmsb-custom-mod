#include "script_component.hpp"
/*
 * Author: YonV
 * ADJUST FIRE, on the server (TAC//SUPPORT v2 build step 6, 2026-11-01): the
 * observer's next call on the mission the battery holds for him, reached from
 * FUNC(request) once FUNC(check) and FUNC(adjustFor) have passed it for the
 * sender - the same remoteExec, the same sender checks as every order.
 *
 *   ADJ_ROUND  an adjusting round - one gun, one round - at the corrected
 *              point the observer sent
 *   ADJ_FFE    the whole order at that point (rounds per gun, guns, sheaf)
 *   ADJ_END    end of mission: the battery stands down (FUNC(finish)), and
 *              the thread closes with what it says
 *
 * Either salvo goes on the SAME mission (its token), so a CHECK FIRE
 * (FUNC(abort)) still stops it, and the battery holds again once it is down
 * (FUNC(adjustHold)). A laid battery answers at its quickest: the module's
 * least response time, no DELAY. The target marker moves to the new point.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The point, ATL <ARRAY>
 * 2: The order's options (FUNC(readOpts)) <ARRAY>
 * 3: The call, ADJ_* <NUMBER>
 * 4: The requester <OBJECT>
 * 5: Asset id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _pos, _opts, 1, _requester, "fires:0"] call jmfsb_support_fires_fnc_adjustNext
 *
 * Public: No
 */

params ["_logic", "_target", "_opts", "_call", "_requester", "_assetId"];

if (!isServer || {isNull _logic}) exitWith {};

private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
private _token = _logic getVariable [QGVAR(token), -1];
// Whatever the battery was waiting out is over: a new call came.
_logic setVariable [QGVAR(holdSeq), (_logic getVariable [QGVAR(holdSeq), 0]) + 1];

if (_call isEqualTo ADJ_END) exitWith {
    INFO_2("adjust: %1 end of mission for %2",_callsign,_requester);
    [_assetId, true, format ["%1 - end of mission", _callsign], _requester] call EFUNC(support,ack);
    [_logic, _token, "end of mission, over"] call FUNC(finish);
};

// AIMING ERROR REMOVED BY ADJUSTING (user, 2026-11-02, from the Tun
// Firesupport review): each correction called takes the error down, and so
// does the fire for effect after them (FUNC(aimError)).
private _steps = _logic getVariable [QGVAR(aimSteps), 0];
if (_call isEqualTo ADJ_ROUND) then {_logic setVariable [QGVAR(aimSteps), _steps + 1]};
if (_call isEqualTo ADJ_FFE && _steps > 0) then {_logic setVariable [QGVAR(aimFfe), true]};

(_logic getVariable [QGVAR(response), [0, 0]]) params [["_respMin", 0]];
private _plan = [_logic, _target, _opts, _token, _respMin] call FUNC(fireVirtual);
if (_plan isEqualTo []) exitWith {
    [_assetId, false, format ["%1: cannot fire that", _callsign], _requester] call EFUNC(support,ack);
};
_plan params ["_shots", "", "_eta"];

[_logic, _target, format ["%1 - %2", _callsign, ["FIRE FOR EFFECT", "ADJUST"] select (_call isEqualTo ADJ_ROUND)], 0] call FUNC(mark);

private _what = if (_call isEqualTo ADJ_ROUND) then {"adjusting round"} else {
    format ["fire for effect, %1 round%2", _shots, ["s", ""] select (_shots isEqualTo 1)]
};
[_assetId, true, format [
    "%1 - %2. Shot in %3 sec, time of flight %4 sec",
    _callsign, _what, round _respMin, round _eta
], _requester] call EFUNC(support,ack);
INFO_3("adjust: %1 %2 at %3",_callsign,_what,mapGridPosition _target);
