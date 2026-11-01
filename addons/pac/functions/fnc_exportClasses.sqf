#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_exportClasses

Description:
    Write what this server actually has loaded into <unit>.classes, so the web
    manager's arsenal and motorpool editors can offer real classnames instead
    of a text box.

    ONLY THE GAME KNOWS. A list of classnames typed on a website goes stale the
    day a mod is added or dropped, and a classname that does not exist is a
    silent hole in an arsenal - the item simply is not there, with nothing said.
    So the list comes from configFile on the server that will run the mission.

    ON DEMAND, NOT AT BOOT. Walking CfgWeapons and CfgVehicles takes a moment
    and the answer only changes when the modset does, so an admin presses the
    button after a mod change rather than paying for it every mission start.

    SCOPE 2 ONLY. scope = 2 is what BI means by "a player can be given this";
    scope 1 is a base class and 0 is hidden. Without that filter the list is
    tens of thousands of entries, most of them useless, and large enough to be
    worth worrying about against the 16 MB a document may hold.

Parameters:
    0: Caller <OBJECT> (optional, default objNull) - told what happened

Returns:
    How many classnames were written <NUMBER>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]]];

if (!isServer) exitWith {0};
// An admin's button: a heavy walk of the config and a database write, so only
// an admin by the server's records may start it (review S5).
if !([] call EFUNC(common,senderIsAdmin)) exitWith {0};

private _fnc_tell = {
    params ["_msg", "_colour"];
    if (!isNull _caller) then {
        ["TAC//PAC", _msg, _colour] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
    };
};

private _t0 = diag_tickTime;

// ---- weapons, magazines and everything a man carries ----------------------
private _weapons = [];
private _magazines = [];
private _items = [];
private _backpacks = [];

{
    private _c = _x;
    private _name = configName _c;
    if (getNumber (_c >> "scope") != 2) then {continue};

    switch (true) do {
        // A backpack is a CfgVehicles Bag_Base, not a weapon - handled below.
        case (isClass (_c >> "WeaponSlotsInfo") || {getNumber (_c >> "type") in [1, 2, 4, 5]}): {
            _weapons pushBack _name;
        };
        default {_items pushBack _name};
    };
} forEach ("true" configClasses (configFile >> "CfgWeapons"));

{
    private _c = _x;
    if (getNumber (_c >> "scope") != 2) then {continue};
    _magazines pushBack configName _c;
} forEach ("true" configClasses (configFile >> "CfgMagazines"));

// ---- vehicles, and the backpacks that live among them --------------------
private _vehicles = [];
{
    private _c = _x;
    private _name = configName _c;
    if (getNumber (_c >> "scope") != 2) then {continue};

    if (_name isKindOf "Bag_Base") then {
        _backpacks pushBack _name;
    } else {
        if (_name isKindOf "AllVehicles") then {_vehicles pushBack _name};
    };
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

private _lists = createHashMapFromArray [
    ["weapons", _weapons],
    ["magazines", _magazines],
    ["items", _items],
    ["backpacks", _backpacks],
    ["vehicles", _vehicles]
];

private _total = 0;
{_total = _total + count (_lists get _x)} forEach (keys _lists);

private _unit = GVAR(settings) getOrDefault ["unitId", ""];
if (_unit isEqualTo "") exitWith {
    ["No unit id, so there is nowhere to write the class list.", [0.831, 0.267, 0.267, 1]] call _fnc_tell;
    0
};

private _doc = createHashMapFromArray [
    ["section", "classes"],
    ["lists", _lists],
    ["from", "the game"],
    ["exportedAt", [] call FUNC(stamp)],
    ["total", _total]
];

// FUNC(svcSave) takes the key and the document already as JSON -
// the same pair FUNC(svcPushStructure) uses to seed a database.
private _sent = [_unit + ".classes", [_doc, ""] call FUNC(toJson)] call FUNC(svcSave);

if (_sent) then {
    [format ["%1 classnames written to '%2.classes' in %3 s - the web manager's arsenal and motorpool editors will offer them.", _total, _unit, (diag_tickTime - _t0) toFixed 1], [0.4, 0.702, 0.4, 1]] call _fnc_tell;
    INFO_2("exported %1 classnames to %2.classes",_total,_unit);
} else {
    ["The class list could not be written - is the database configured?", [0.831, 0.267, 0.267, 1]] call _fnc_tell;
};

_total
