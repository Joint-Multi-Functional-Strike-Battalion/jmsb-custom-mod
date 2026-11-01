#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_productPackage

Description:
    Hands over a share of the intel package attached to the device that was
    hacked, and remembers what has already been taken off it.

    A SHARE, NOT THE LOT. One break-in yields part of what is on the terminal -
    how much is FUNC(hackSetting) QGVAR(cfg_package_share), a percentage, so a
    mission maker writes eight entries and a unit gets them over several visits
    rather than one. That is the whole reason a device is worth coming back to,
    and the reason a hack is worth doing quietly rather than blowing the mast up
    afterwards.

    ALWAYS AT LEAST ONE ENTRY. A share that rounds to nothing is a hack that
    succeeded and delivered silence, which reads as a bug to the man who did it.
    Whatever the percentage works out to, a successful break-in hands over
    something.

    FROM THE TOP, AND NEVER TWICE. Entries come in config order and each side
    keeps its own tally per device, so a second hack continues where the first
    stopped instead of re-rolling the same page. When the tally reaches the end
    there is nothing left on that terminal - it says so, and it says so
    differently from "there was never anything here", because those are
    different facts about the mission.

    PER SIDE, NOT PER PLAYER. Intel handed to a unit belongs to the unit. Two
    men hacking the same terminal are one effort, not two, and the second one
    should not be able to farm the first page again by being a different person.

Parameters:
    _device : OBJECT - what was hacked.
    _side   : SIDE   - who earned it.
    _caller : OBJECT - the hacker, for the message.

Returns:
    BOOL - whether anything was handed over.

Author:
    YonV
---------------------------------------------------------------------------- */
if (!isServer) exitWith { false };

params [["_device", objNull, [objNull]], ["_side", sideUnknown, [sideUnknown]],
        ["_caller", objNull, [objNull]]];

if (isNull _device) exitWith { false };

private _package = _device getVariable [QGVAR(package), ""];
if (_package isEqualTo "") exitWith { false };

private _entries = [_package] call FUNC(packageEntries);
if (_entries isEqualTo []) exitWith { false };

// WHAT THIS SIDE HAS ALREADY HAD OFF THIS DEVICE. Kept on the device rather
// than in one central ledger: the device is the thing that gets destroyed, and
// its tally should die with it.
private _key = format [QGVAR(taken_%1), _side];
private _taken = _device getVariable [_key, 0];

if (_taken >= count _entries) exitWith {
    ["This terminal has nothing further on it.", _side] remoteExecCall [QFUNC(pickResult), 0];
    false
};

private _share = [QGVAR(cfg_package_share)] call FUNC(hackSetting);
private _count = round ((count _entries) * (_share / 100)) max 1;

private _slice = _entries select [_taken, _count];
_device setVariable [_key, _taken + count _slice, true];

// The package's own display name, so the app can file the entries under the
// thing they came from rather than under the class name a mission maker chose
// for their own convenience.
private _label = getText (missionConfigFile >> "Jmfsb_IntelPackages" >> _package >> "name");
if (_label isEqualTo "") then { _label = toUpper _package };

// THE STORE IS BROADCAST, because the app that reads it runs on every client
// and a man who was not the hacker still has the intel his unit holds.
private _store = missionNamespace getVariable [QGVAR(packageIntel), createHashMap];
private _held = _store getOrDefault [str _side, []];

{
    _x params ["_id", "_title", "_text", "_image"];
    _held pushBack [_package, _label, _id, _title, _text, _image];
} forEach _slice;

_store set [str _side, _held];
missionNamespace setVariable [QGVAR(packageIntel), _store, true];

private _left = (count _entries) - (_taken + count _slice);

INFO_3("package '%1': %2 entries to %3",_package,count _slice,_side);

[
    format [
        "%1 - %2 file%3 recovered.%4",
        _label,
        count _slice,
        ["", "s"] select (count _slice > 1),
        [" Nothing further on this terminal.", ""] select (_left > 0)
    ],
    _side
] remoteExecCall [QFUNC(pickResult), 0];

true
