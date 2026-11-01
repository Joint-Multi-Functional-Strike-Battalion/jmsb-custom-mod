#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//SUPPORT: sends the request CONFIRM TASKING stands for - the selected
 * asset and task, the target point and the parameter array - and says what
 * came back. One function, because two presses send it: CONFIRM itself, and
 * YES on the danger-close question the board asks first when a friendly is
 * inside the danger-close distance of the point (FUNC(supportDangerClose)).
 *
 * INGRESS, EGRESS AND EVERY DECLARED POINT RIDE IN THE PARAMETER ARRAY, past
 * everything ALiVE's own tasking reads, so one array serves every kind of
 * asset - see FUNC(supportRequestParams).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The request was accepted <BOOL>
 *
 * Example:
 * [] call jmfsb_tacpad_apps_fnc_supportConfirm
 *
 * Public: No
 */

private _sel = missionNamespace getVariable [QGVAR(supportSel), ["cas", "", ""]];
private _prm = [] call FUNC(supportRequestParams);

(
    [
        _sel # 1, _sel # 2,
        missionNamespace getVariable [QGVAR(supportPoint), []],
        _prm
    ] call EFUNC(support,request)
) params ["_ok", "_why"];

// WHAT WAS ACCEPTED, IN THE WORDS OF THE THING THAT ACCEPTED IT - the
// callsign read back off the asset list. An accepted order also becomes
// the committed tasking, which lights its task row in the accent.
private _said = if (_ok) then {
    missionNamespace setVariable [QGVAR(supportCommitted), [_sel # 1, _sel # 2, CBA_missionTime]];
    private _assets = call EFUNC(support,assets);
    private _row = _assets param [_assets findIf {(_x param [0, ""]) isEqualTo (_sel # 1)}, []];
    private _cs = _row param [2, "UNIT"];
    private _at = missionNamespace getVariable [QGVAR(supportPoint), []];

    if (_at isEqualTo []) then {
        format ["%1 ACCEPTED - %2", _cs, _sel # 2]
    } else {
        format ["%1 ACCEPTED - %2 ON %3", _cs, _sel # 2, mapGridPosition _at]
    }
} else {
    _why
};
missionNamespace setVariable [QGVAR(supportFlash), [_said, _ok, CBA_missionTime]];
["SUPPORT", _said, ["high", "normal"] select _ok] call EFUNC(messaging,notify);
{[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;

_ok
