#include "script_component.hpp"
/*
 * Author: JMSB
 * Waits for ALiVE to finish standing up, then declares the adapter ready.
 *
 * Every read sits behind this. ALiVE populates OPCOM_instances and the
 * profile system asynchronously, and a read that races init returns nothing -
 * which a caller cannot tell apart from "there is nothing there". Readiness
 * is: the globals exist, at least one commander, and every commander
 * reporting startupComplete.
 *
 * Runs the FUNC(whenReady) hooks once. Not the "jmfsb_adapter_alive_ready"
 * CBA event any more (review R1): any client could raise that one again and
 * restart every system that starts on it - air defence, leaders, QRF, UAS.
 * The truth is the server's, in localNamespace; GVAR(ready) is a copy for
 * readers.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

if (!isServer) exitWith {};
if (localNamespace getVariable [QGVAR(ready), false]) exitWith {};

[{
    params ["_args", "_handle"];
    _args params ["_t0"];

    private _ok = !isNil "OPCOM_instances"
        && {!isNil "ALIVE_profileHandler"}
        && {count OPCOM_instances > 0}
        && {
            (OPCOM_instances findIf {
                !([_x, "startupComplete", false] call ALiVE_fnc_hashGet)
            }) < 0
        };

    if (_ok) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        if (localNamespace getVariable [QGVAR(ready), false]) exitWith {};
        localNamespace setVariable [QGVAR(ready), true];
        GVAR(ready) = true;
        INFO_2("ALiVE up after %1s - %2 commander(s). Adapter ready.",
            round (CBA_missionTime - _t0),count OPCOM_instances);
        private _hooks = localNamespace getVariable [QGVAR(readyHooks), []];
        localNamespace setVariable [QGVAR(readyHooks), []];
        {
            _x params ["_code", "_args"];
            _args call _code;
        } forEach _hooks;
    };

    // An adapter that never becomes ready must be diagnosable from the RPT
    // rather than being a silence.
    private _waited = CBA_missionTime - _t0;
    if (_waited > 0 && {(round _waited) mod READY_REPORT < READY_POLL}) then {
        INFO_1("waiting on ALiVE init (%1s)...",round _waited);
    };
}, READY_POLL, [CBA_missionTime]] call CBA_fnc_addPerFrameHandler;
