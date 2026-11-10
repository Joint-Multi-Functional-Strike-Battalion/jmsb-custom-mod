#include "script_component.hpp"
/*
 * Author: YonV
 * Waits for ALiVE to finish standing up, then declares the adapter ready - or,
 * when the mission has no commander at all, declares ALiVE absent.
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
 * SAME AS NOT LOADED (user, 2026-11-02). ALiVE loaded but no commander placed
 * waited here forever, and every system that starts on whenReady never
 * started. Still no commander after READY_GIVE_UP: one RPT warning, ALiVE is
 * absent for the mission (server truth in localNamespace, public copy in
 * GVAR(absent)), and every hook runs its fallback - the feature's own path
 * without ALiVE. EFUNC(common,aliveLoaded) answers no from then on. Commanders
 * that exist but are still starting up are waited for, as before.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

if (!isServer) exitWith {};
if (localNamespace getVariable [QGVAR(ready), false]) exitWith {};
if (localNamespace getVariable [QGVAR(absent), false]) exitWith {};

[{
    params ["_args", "_handle"];
    _args params ["_t0"];

    // TRAINING HOLD (FUNC(hold)): ALiVE is up but paused - nothing starts on
    // it until an admin starts it.
    private _held = localNamespace getVariable [QGVAR(held), false];

    private _ok = !_held
        && {!isNil "OPCOM_instances"}
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

    private _waited = CBA_missionTime - _t0;

    // NO COMMANDER AT ALL, AND THE WAIT IS OVER. A nil list is checked
    // before it is read - a nil OPCOM_instances is an error to count.
    private _none = isNil "OPCOM_instances";
    if (!_none) then {_none = OPCOM_instances isEqualTo []};
    if (_none && (_waited >= READY_GIVE_UP)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        localNamespace setVariable [QGVAR(absent), true];
        missionNamespace setVariable [QGVAR(absent), true, true];
        WARNING_1("no ALiVE commander after %1s - ALiVE treated as not loaded for this mission",round _waited);
        private _hooks = localNamespace getVariable [QGVAR(readyHooks), []];
        localNamespace setVariable [QGVAR(readyHooks), []];
        {
            _x params ["", "_args", ["_fallback", {}]];
            _args call _fallback;
        } forEach _hooks;
    };

    // An adapter that never becomes ready must be diagnosable from the RPT
    // rather than being a silence.
    if (_waited > 0 && {(round _waited) mod READY_REPORT < READY_POLL}) then {
        if (_held) then {
            INFO_1("ALiVE held for training (%1s) - #jmfsbalivestart to start",round _waited);
        } else {
            INFO_1("waiting on ALiVE init (%1s)...",round _waited);
        };
    };
}, READY_POLL, [CBA_missionTime]] call CBA_fnc_addPerFrameHandler;
