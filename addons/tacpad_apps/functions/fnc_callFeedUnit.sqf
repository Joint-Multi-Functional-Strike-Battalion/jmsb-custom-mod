#include "script_component.hpp"
/*
 * Author: YonV
 * Who the call's picture shows (FUNC(callFeed)), and what his camera sends:
 * on the player's live call, the other man talking on it now, else the one
 * shown last, else the first other member. What he sends is his own choice
 * (FUNC(callCamFlip)), public on him; FACE until he flips it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [] with no live call; else [unit, send CALL_CAM_FACE / CALL_CAM_VIEW,
 * caption] - unit objNull and caption "NO PICTURE" when nobody else on the
 * call is alive <ARRAY>
 *
 * Example:
 * ([] call jmfsb_tacpad_apps_fnc_callFeedUnit) params ["_unit", "_send", "_caption"]
 *
 * Public: No
 */

if (isNil QEFUNC(voice,calls)) exitWith {[]};

private _me = call CBA_fnc_currentUnit;
private _live = ([] call EFUNC(voice,calls)) select {(_x param [1, ""]) isEqualTo CALL_LIVE};
if (_live isEqualTo []) exitWith {[]};

private _others = ((_live select 0) param [2, []]) select {!isNull _x && {alive _x} && _x isNotEqualTo _me};

// Who talks on the call net now, by the voice API's own talkers.
private _talking = [];
{
    if ((_x param [2, ""]) isEqualTo VOICE_KIND_CALL) then {
        _talking append ((_x param [7, []]) apply {_x param [0, objNull]});
    };
} forEach ([] call EFUNC(voice,netState));
_talking = _talking select {_x in _others};

private _last = uiNamespace getVariable [QGVAR(callFeedLast), objNull];
private _unit = switch (true) do {
    case (_talking isNotEqualTo []): {_talking select 0};
    case (_last in _others): {_last};
    default {_others param [0, objNull]};
};
uiNamespace setVariable [QGVAR(callFeedLast), _unit];

if (isNull _unit) exitWith {[objNull, CALL_CAM_FACE, "NO PICTURE"]};

private _send = _unit getVariable [QGVAR(callCam), CALL_CAM_FACE];
[_unit, _send, format ["%1 %2 %3", toUpper name _unit, MIDDOT_TEXT, ["FACE", "VIEW"] select (_send isEqualTo CALL_CAM_VIEW)]]
