#include "..\script_component.hpp"
/*
 * Author: YonV
 * Unpacks a Boo Boo Bag: a progress bar, then the bag is taken and
 * GVAR(contentsFirstAid) is issued.
 *
 * THE BAG IS CHECKED AND TAKEN WHEN THE BAR COMPLETES (review L3), in the
 * bar's own success callback. Two global flags and a spawned waitUntil used to
 * carry the result, so two unpacks running at once both read one success and
 * issued the bag twice.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call jmfsb_medbags_fnc_doUnpackFirstAid
 *
 * Public: No
 */

#define UNPACK_TIME 2

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {};

_unit playAction "Gear";

if (!isNull objectParent _unit) then {
    playSound QGVAR(Medical_FirstAid_Open_1);
} else {
    playSound3D ["z\jmfsb\addons\medbags\data\sounds\FirstAid_Open_1.ogg", _unit];
};

[
    UNPACK_TIME,
    [_unit],
    {
        (_this select 0) params ["_unit"];
        if !(QGVAR(FirstAid) in items _unit) exitWith {};
        _unit removeItem QGVAR(FirstAid);
        [_unit, GVAR(contentsFirstAid)] spawn FUNC(issueContents);
    },
    {},
    "Unpacking Boo Boo Bag....",
    {true},
    ["isNotInside", "isNotSitting", "isNotSwimming"]
] call ACE_common_fnc_progressBar;
