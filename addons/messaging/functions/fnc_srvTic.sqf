#include "script_component.hpp"
/*
 * Author: YonV
 * TROOPS IN CONTACT. Carried over from the cTab template of the same name.
 *
 * A TIC was never really a message - it was an alarm somebody typed into a
 * message form, and it is the one report that reaches people it was not
 * addressed to. In cTab that behaviour was hardcoded against the template's
 * uid; here it is a template flag, so a mission can put it on another report
 * without editing any code.
 *
 * It goes out on the shared alert bus rather than straight to the notification
 * widget, so it lands in the same list as every other thing that went bang and
 * anything else listening to that bus hears it too.
 *
 * Arguments:
 * 0: Sending player <OBJECT>
 * 1: Thread <HASHMAP>
 * 2: Payload <ARRAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_thread", createHashMap, [createHashMap]], ["_payload", [], [[]]]];

if (!isServer || {isNull _unit}) exitWith {};
if (!GVAR(ticBroadcast) && {!GVAR(ticMarker)}) exitWith {};

private _pos = _thread getOrDefault ["anchorPos", getPosATL _unit];
private _grid = mapGridPosition _pos;
private _callsign = groupId (group _unit);
private _side = side (group _unit);

// ONE LABEL, USED TWICE. The marker on the map and the alert that told you to
// look at it have to say the same thing or they are two contacts - so the call
// sign and the time it went in are composed once here. The time is what tells a
// man scanning a map with four TIC marks on it which one is happening NOW.
date params ["", "", "", "_hh", "_mm"];
private _label = format [
    "TIC %1 %2%3",
    _callsign,
    [_hh, 2] call CBA_fnc_formatNumber,
    [_mm, 2] call CBA_fnc_formatNumber
];

if (GVAR(ticBroadcast)) then {
    private _text = format ["%1 in contact - %2", _callsign, _label];

    // common's alert bus has no side filter and a TIC is not for the other
    // side, so the targeting is done here and the bus's own client handler does
    // the rest. Severity 2 is what makes it speak up rather than only file.
    // By remoteExec, which the client takes only from the server (review S7).
    private _told = allPlayers select {alive _x && {side (group _x) isEqualTo _side}};
    if (_told isNotEqualTo []) then {
        ["TIC", _text, _grid, 2, 300] remoteExecCall [QEFUNC(common,onAlert), _told];
    };
};

if (GVAR(ticMarker)) then {
    private _name = format [QGVAR(tic_%1), _thread get "id"];

    // Drawn locally on the sender's side rather than created globally, because
    // a global marker is on the enemy's map too and a contact report that tells
    // the enemy where the contact is has the wrong readership.
    {
        [_name, _pos, _label] remoteExecCall [QFUNC(cltMarker), _x];
    } forEach (allPlayers select {alive _x && {side (group _x) isEqualTo _side}});

    // The thread carries its marker name so the sweep can take it away with the
    // thread. A marker nobody removes is why old missions end up wallpapered
    // in red.
    _thread set ["marker", _name];
};
