#include "script_component.hpp"
/*
    File: fn_motorpool_open.sqf
    Author: YonV/JMSB
    Description: Opens the MOTORPOOL spawner screen for one controller/pad
        pair and paints every control from the jmfsb mod's colour scheme
        (jmfsb_tacpad_fnc_theme; the design's Field Grey when the mod is
        absent). Builds the category tabs from MotorPool_Common plus the
        player's squad config - see fn_motorpool_squadClass - and always
        ends the row with SPAWNED, where removal lives. The offering is
        filtered to the pad's own category switches from its init line -
        see fn_motorpool_init.

    Arguments:
    0: Controller <OBJECT> - the object carrying the ledger
    1: Pad <OBJECT> - named helper (invisible helipad) vehicles appear on

    Example:
    [_controller, _pad] call jmfsb_vehicle_fnc_motorpool_open;
*/

params [["_controller", objNull, [objNull]], ["_pad", objNull, [objNull]]];

if (isNull _pad) then {_pad = _controller};

createDialog "YMF_MotorPool";
private _d = uiNamespace getVariable ["YMF_motorpool_dlg", displayNull];
if (isNull _d) exitWith {};

// The mod's palette; ground forced opaque - this is a dialog, and a
// translucent ground over the 3D world is mud (the TAC//SUPPORT lesson).
private _theme = if (!isNil "jmfsb_tacpad_fnc_theme") then {
    +([] call jmfsb_tacpad_fnc_theme)
} else {
    [[0.953, 0.949, 0.949, 1], [0.125, 0.118, 0.114, 1], [0.925, 0.188, 0.075, 1], [0.125, 0.118, 0.114, 0.22]]
};
private _ground = +(_theme select 0);
_ground set [3, 1];
_theme set [0, _ground];

uiNamespace setVariable ["YMF_motorpool_theme", _theme];
uiNamespace setVariable ["YMF_motorpool_ctx", [_controller, _pad]];

_theme params ["", "_ink", "_accent"];
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _band = [_ink # 0, _ink # 1, _ink # 2, 0.1];

// ---------------------------------------------------------- the repaint ---
{(_d displayCtrl _x) ctrlSetBackgroundColor _ground} forEach [900, 100, 105];
{(_d displayCtrl _x) ctrlSetBackgroundColor _ink} forEach [903, 904];
{(_d displayCtrl _x) ctrlSetBackgroundColor _band} forEach [125, 160];
{(_d displayCtrl _x) ctrlSetTextColor _ink} forEach [101, 106, 126, 161];
{(_d displayCtrl _x) ctrlSetTextColor _mute} forEach [102, 107, 121, 127, 162, 163, 165];
{
    (_d displayCtrl _x) ctrlSetBackgroundColor [_ink # 0, _ink # 1, _ink # 2, 0.05];
    (_d displayCtrl _x) ctrlSetTextColor _ink;
} forEach [120, 130, 164, 166];
(_d displayCtrl 170) ctrlSetBackgroundColor _accent;
(_d displayCtrl 170) ctrlSetTextColor _ground;
(_d displayCtrl 171) ctrlSetBackgroundColor _ground;
(_d displayCtrl 171) ctrlSetTextColor _ink;

// ------------------------------------------------ what this pad may offer --
// Seven switches on the pad's own init line, in config order -
// [this, pad, cars, armor, mech, heli, plane, boat, static] - because the pad
// itself cannot say: helipads snap to the ground, so a dock pad and a
// motor yard read the same to every surface test. Filtering keys on the
// category CLASS NAME in the common and squad files; a category outside
// the six named ones is always offered, and a category switched off
// vanishes with the existing empty-category rule.
private _allow = _controller getVariable ["YMF_motorpool_allow", [true, true, true, true, true, true, true]];
// CATEGORY CLASS NAME -> WHICH OF THE SEVEN SWITCHES IT ANSWERS TO. The first
// seven are the switches themselves, in the order the init line passes them.
//
// THE THREE DRONE TABS RIDE THEIR DOMAIN'S SWITCH (user, 2026-09-01), and that
// is what this hash exists for - a plain findIf over the seven names could only
// ever match a category called exactly Cars, Heli or Boat. DRONES (GND) follows
// Cars, DRONES (AIR) follows Heli and DRONES (SEA) follows Boat, so a ground pad
// offers ground drones, the air pad offers air drones and the dock offers the
// Magura. Before this they were outside the switch system entirely, which is
// what put an unmanned surface vessel on a motor yard.
//
// A category named here but absent from a pad's switches is still offered - the
// rule below only ever refuses, never adds - so a squad config inventing its own
// tab is unaffected.
private _catSwitch = createHashMapFromArray [
    ["Cars", 0], ["Armor", 1], ["Mech", 2], ["Heli", 3], ["Plane", 4], ["Boat", 5], ["Static", 6],
    ["DronesGround", 0], ["DronesAir", 3], ["DronesSea", 5]
];

// --------------------------------------------------------- the categories --
// Common first, then the squad's own list appended into the same category
// names - the arsenal's merge, done to vehicles. A category nobody stocked
// disappears; classes absent from the modset are dropped here, once.
private _sources = [missionConfigFile >> "MotorPool_Common"];
private _squadCfg = call jmfsb_vehicle_fnc_motorpool_squadClass;
if (!isNull _squadCfg) then {_sources pushBack _squadCfg};

private _cats = [];
{
    {
        private _cat = _x;
        private _catName = configName _cat;
        private _switch = _catSwitch getOrDefault [_catName, -1];
        if (_switch > -1 && {!(_allow param [_switch, true])}) then {continue};

        private _label = toUpper _catName;
        if (isText (_cat >> "displayName")) then {_label = toUpper getText (_cat >> "displayName")};

        private _rows = (getArray (_cat >> "vehicles")) select {
            isClass (configFile >> "CfgVehicles" >> _x)
        };
        if (_rows isNotEqualTo []) then {
            private _at = _cats findIf {(_x select 0) isEqualTo _label};
            if (_at < 0) then {
                _cats pushBack [_label, _rows];
            } else {
                private _merged = ((_cats select _at) select 1) + _rows;
                (_cats select _at) set [1, _merged arrayIntersect _merged];
            };
        };
    } forEach ("true" configClasses _x);
} forEach _sources;

// THE DATABASE'S CATEGORIES, APPENDED THE SAME WAY. <unit>.motorpool holds
// {items: {Cars: {displayName, vehicles[]}}}, so it merges into the category
// names the mission already built rather than replacing them - a mission that
// ships config_motorpool_common.hpp and one that ships none both work.
if (!isNil "jmfsb_pac_structure") then {
    private _mp = +(jmfsb_pac_structure getOrDefault ["motorpool", createHashMap]);

    // A PAD THAT NAMES ITS OWN MOTORPOOL (init arg 11, 2026-11-07) shows that
    // one of the unit's pools - "air" at the airfield - not the mission's.
    private _pool = _controller getVariable ["YMF_motorpool_pool", ""];
    if (_pool isNotEqualTo "") then {
        private _own = (jmfsb_pac_structure getOrDefault ["motorpoolVariants", createHashMap]) getOrDefault [_pool, createHashMap];
        if (_own isEqualType createHashMap && {count _own > 0}) then {_mp = +_own};
    };

    // AND THE SQUAD'S OWN POOL FROM THE DATABASE (2026-09-09), merged into the
    // common one before either is read - the same two sources the config path
    // above uses, from the other side. The variant is named exactly as the
    // mission class was, "MotorPool_Nomad" for a group called "NOMAD 2-1", so
    // the two paths answer the same thing for the same squad.
    //
    // MATCHED WITHOUT CASE. groupId gives "NOMAD", the document is
    // "MotorPool_Nomad", and a hashmap - unlike a config path - cares.
    private _first = ((groupId group player) splitString " -") param [0, ""];
    if (_first isNotEqualTo "") then {
        private _want = toLower format ["MotorPool_%1", _first];
        private _variants = jmfsb_pac_structure getOrDefault ["motorpoolVariants", createHashMap];
        {
            if (toLower _x isEqualTo _want) exitWith {
                private _v = _variants get _x;
                if (_v isEqualType createHashMap) then {
                    {
                        private _cat = _v get _x;
                        if !(_cat isEqualType createHashMap) then {continue};
                        private _at = _mp getOrDefault [_x, createHashMap];
                        if (count _at isEqualTo 0) then {
                            _mp set [_x, _cat];
                        } else {
                            // Same category in both: the vehicles add up.
                            private _merged = +_at;
                            _merged set ["vehicles",
                                (_at getOrDefault ["vehicles", []]) + (_cat getOrDefault ["vehicles", []])];
                            _mp set [_x, _merged];
                        };
                    } forEach (keys _v);
                };
            };
        } forEach (keys _variants);
    };
    {
        private _cat = _mp get _x;
        if (_cat isEqualType createHashMap) then {
            private _label = toUpper ([_cat getOrDefault ["displayName", _x], _x] select ((_cat getOrDefault ["displayName", ""]) isEqualTo ""));
            private _rows = (_cat getOrDefault ["vehicles", []]) select {
                _x isEqualType "" && {isClass (configFile >> "CfgVehicles" >> _x)}
            };
            if (_rows isNotEqualTo []) then {
                private _at = _cats findIf {(_x select 0) isEqualTo _label};
                if (_at < 0) then {
                    _cats pushBack [_label, _rows];
                } else {
                    private _merged = ((_cats select _at) select 1) + _rows;
                    (_cats select _at) set [1, _merged arrayIntersect _merged];
                };
            };
        };
    } forEach (keys _mp);
};

// ------------------------------------------------- the pad's own vehicles --
// Listed on the init line (arg 10), sorted onto their kind's tab AFTER the
// switch filter ran - a class named for this pad is offered whatever the
// switches say, so one pad can carry a single helicopter with the whole
// HELI category otherwise off.
private _fnc_kindLabel = {
    params ["_cls"];
    switch (true) do {
        case (_cls isKindOf "Helicopter"): {"HELI"};
        case (_cls isKindOf "Plane"): {"PLANE"};
        case (_cls isKindOf "Ship"): {"BOAT"};
        case (_cls isKindOf "Wheeled_APC_F"): {"MECHANIZED"};
        case (_cls isKindOf "Tank"): {"ARMOR"};
        case (_cls isKindOf "StaticWeapon"): {"STATIC"};
        default {"CARS"};
    }
};
{
    private _cls = _x;
    if (isClass (configFile >> "CfgVehicles" >> _cls)) then {
        private _label = [_cls] call _fnc_kindLabel;
        private _at = _cats findIf {(_x select 0) isEqualTo _label};
        if (_at < 0) then {
            _cats pushBack [_label, [_cls]];
        } else {
            private _merged = ((_cats select _at) select 1) + [_cls];
            (_cats select _at) set [1, _merged arrayIntersect _merged];
        };
    };
} forEach (_controller getVariable ["YMF_motorpool_extra", []]);

// seven category slots plus SPAWNED - the tab row is eight buttons wide
if (count _cats > 7) then {_cats resize 7};
_cats pushBack ["SPAWNED", []];
uiNamespace setVariable ["YMF_motorpool_cats", _cats];

(_d displayCtrl 102) ctrlSetText format ["%1 - GRID %2", groupId group player, mapGridPosition player];

[0] call jmfsb_vehicle_fnc_motorpool_tab;
