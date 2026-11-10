#include "script_component.hpp"
/*
 * Author: YonV
 * Every change the timer can be asked for, in one place: start, stop, reset, and
 * moving the countdown mark.
 *
 * THE RING IS ARMED, NOT POLLED. A countdown that only went off while somebody
 * had the map open would be a countdown you cannot trust, and a per-frame handler
 * running for twenty minutes to notice one moment is twenty minutes of nothing.
 * Starting a countdown schedules the ring; stopping or resetting invalidates it
 * by bumping a token the waiter checks when it fires.
 *
 * Arguments:
 * 0: What to do - "toggle", "reset", "step" <STRING>
 * 1: Seconds to move the mark by, for "step" <NUMBER> (optional, default 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["step", 300] call jmfsb_tacpad_apps_fnc_timerSet
 *
 * Public: No
 */

params [["_what", "", [""]], ["_step", 0, [0]]];

private _accum = missionNamespace getVariable [QGVAR(timerAccum), 0];
private _since = missionNamespace getVariable [QGVAR(timerSince), -1];
private _target = missionNamespace getVariable [QGVAR(timerTarget), 0];
private _running = _since >= 0;

// Any change invalidates a pending ring. The waiter compares this when it fires,
// so a countdown that was stopped and restarted rings once, at the new time.
private _token = (missionNamespace getVariable [QGVAR(timerToken), 0]) + 1;
GVAR(timerToken) = _token;

switch (_what) do {
    case "toggle": {
        if (_running) then {
            GVAR(timerAccum) = _accum + (CBA_missionTime - _since);
            GVAR(timerSince) = -1;
        } else {
            GVAR(timerSince) = CBA_missionTime;
        };
    };

    case "reset": {
        GVAR(timerAccum) = 0;
        GVAR(timerSince) = -1;
    };

    case "step": {
        // The mark moves, the clock does not. Stepping while it runs is how a
        // man extends a countdown he is already inside.
        GVAR(timerTarget) = 0 max (_target + _step);

        // Down to nothing is a stopwatch again, and a stopwatch has no mark to
        // ring on.
        if (GVAR(timerTarget) <= 0) then {
            GVAR(timerTarget) = 0;
        };
    };
};

// Re-arm from whatever the state is now.
private _state = [] call FUNC(timerState);
_state params ["_left", "_nowRunning", "_isDown", "_expired"];

if (!_isDown || {!_nowRunning} || _expired) exitWith {};

[{
    params ["_token"];
    (missionNamespace getVariable [QGVAR(timerToken), 0]) isNotEqualTo _token
    || {([] call FUNC(timerState)) # 3}
}, {
    params ["_token"];
    if ((missionNamespace getVariable [QGVAR(timerToken), 0]) isNotEqualTo _token) exitWith {};

    // Onto the alert bus, LOCALLY. EFUNC(common,alert) is the server's end - it
    // decides who within a radius hears something the mission did to them - and
    // a man's own timer is nobody else's business. FUNC(onAlert) is the client
    // half that files the entry and speaks up at severity 2, which is what the
    // scanner panel and the EW screen read back.
    ["TIMER", "Countdown expired.", "", 2, 60] call EFUNC(common,onAlert);
}, [_token]] call CBA_fnc_waitUntilAndExecute;
