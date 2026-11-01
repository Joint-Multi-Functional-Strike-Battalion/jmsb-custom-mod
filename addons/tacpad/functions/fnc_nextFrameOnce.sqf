#include "script_component.hpp"
/*
 * Author: JMSB
 * Runs a redraw next frame, once however many times it is asked for this
 * frame (code review R8: one redraw per frame). The first ask queues it
 * (CBA_fnc_execNextFrame) under its id; every further ask before it runs is
 * already answered by that one, which reads the state as it is by then.
 *
 * The pending mark is cleared before the code runs, so a redraw that throws
 * cannot leave its id stuck, and a redraw that asks again queues a new one.
 * Kept in missionNamespace, so a mission that ends with one queued leaves
 * nothing behind.
 *
 * Arguments:
 * 0: Id of the redraw <STRING>
 * 1: The redraw <CODE>
 * 2: Its arguments <ANY> (optional, default [])
 *
 * Return Value:
 * Queued by this call - false when one was already waiting <BOOL>
 *
 * Example:
 * ["jmfsb_tacpad_readerDraw", {[] call jmfsb_tacpad_fnc_readerDraw}] call jmfsb_tacpad_fnc_nextFrameOnce
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_code", {}, [{}]], ["_args", []]];

private _pending = missionNamespace getVariable [QGVAR(nextFrame), createHashMap];
missionNamespace setVariable [QGVAR(nextFrame), _pending];
if (_id in _pending) exitWith {false};
_pending set [_id, true];

[{
    params ["_id", "_code", "_args"];
    (missionNamespace getVariable [QGVAR(nextFrame), createHashMap]) deleteAt _id;
    _args call _code;
}, [_id, _code, _args]] call CBA_fnc_execNextFrame;

true
