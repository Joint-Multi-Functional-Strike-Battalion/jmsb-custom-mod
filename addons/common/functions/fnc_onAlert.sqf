#include "script_component.hpp"
/*
 * Author: YonV
 * Receives an alert on the client, keeps it, and says it out loud once.
 *
 * Kept in a list rather than only shown, because the two jobs are different: a
 * popup is for the moment it happens, and the device's ALERTS page is for the
 * minute afterwards when you want to know what that bang was. Same event feeds
 * both, so they can never disagree.
 *
 * Sorted newest first and trimmed, so a long mission does not accumulate a
 * thousand entries nobody will scroll to.
 *
 * Sent by remoteExecCall from the server (FUNC(alert), messaging's srvTic) and
 * taken only from the server, or called on this machine for its own alert (the
 * tacpad's TIMER) - review S7. It was a CBA event, and any client could raise
 * that one to put a red danger popup on every screen.
 *
 * Arguments:
 * 0: Source <STRING>
 * 1: Text <STRING>
 * 2: Grid, "" if nowhere in particular <STRING>
 * 3: Severity 0-2 <NUMBER>
 * 4: Lifetime, seconds <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["TIMER", "Countdown expired.", "", 2, 60] call jmfsb_common_fnc_onAlert
 *
 * Public: Yes
 */

if (!hasInterface) exitWith {};
if !([] call FUNC(fromServer)) exitWith {};
params [["_source", "", [""]], ["_text", "", [""]], ["_grid", "", [""]], ["_severity", 1, [0]], ["_life", 120, [0]]];

private _alerts = missionNamespace getVariable [QGVAR(alerts), []];

// drop what has expired before adding, so the list tidies itself
private _now = CBA_missionTime;
_alerts = _alerts select {(_x select 4) > _now};

_alerts insert [0, [[_source, _text, _grid, _severity, _now + _life]]];
if (count _alerts > ALERT_KEEP) then {
    _alerts resize ALERT_KEEP;
};
GVAR(alerts) = _alerts;

// Danger speaks up. A note does not - it is there to be looked up, and a
// popup for every drone that takes off trains people to ignore popups.
if (_severity >= 2 && {!isNil "jmfsb_notify_fnc_notify"}) then {
    private _line = if (_grid == "") then {_text} else {format ["%1 - grid %2", _text, _grid]};
    [_source, _line, [1, 0.30, 0.30, 1]] call jmfsb_notify_fnc_notify;
};
