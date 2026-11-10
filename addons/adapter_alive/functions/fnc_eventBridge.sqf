#include "script_component.hpp"
/*
 * Author: YonV
 * Subscribes to ALiVE's event log once, on the server, after the adapter is
 * ready. From then on every ALiVE event reaches jmfsb as a plain CBA event -
 * see FUNC(eventListener) for the names and the summaries.
 *
 * Polling was the alternative and is what everything did: re-read a pool on
 * a timer and notice a change a beat late. ALiVE tells its listeners the
 * moment an objective changes hands or a convoy arrives; this is that.
 *
 * The listener is an ALiVE hash whose "class" names the handler function -
 * the shape ALiVE's own listeners use (x_lib fnc_eventLog.sqf:229-238).
 *
 * Arguments: None
 *
 * Return Value:
 * Listener id <NUMBER>, -1 if nothing was registered
 *
 * Public: No
 */

if (!isServer || {isNil "ALIVE_eventLog"}) exitWith {-1};
if (!isNil QGVAR(listenerId)) exitWith {GVAR(listenerId)};

private _listener = [] call ALiVE_fnc_hashCreate;
[_listener, "class", QFUNC(eventListener)] call ALiVE_fnc_hashSet;
GVAR(listenerId) = [ALIVE_eventLog, "addListener", [_listener, ["ALL"]]] call ALIVE_fnc_eventLog;
INFO_1("ALiVE event bridge up (listener %1)",GVAR(listenerId));
GVAR(listenerId)
