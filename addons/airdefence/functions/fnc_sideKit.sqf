#include "script_component.hpp"
/*
 * Author: YonV
 * What a commander fields for air defence: a radar, a launcher and a MANPAD.
 *
 * The module's own class attributes win when a mission sets them. Left blank,
 * the classes are drawn FROM THE COMMANDER'S OWN FACTION, so an Iranian
 * commander gets Iranian hardware without anybody typing a class list - and a
 * mission set this addon has never heard of works without being taught.
 *
 * Vanilla is the floor, not the intent: it is only reached when the faction
 * fields nothing that matches, which is worth saying in the log rather than
 * silently dropping NATO hardware into somebody's insurgent force.
 *
 * Cached per faction. The config sweep is over every vehicle class in the
 * mission and is not something to do once per site.
 *
 * Arguments:
 * 0: The faction <STRING>
 * 1: The side, for the vanilla floor <SIDE>
 *
 * Return Value:
 * [radar, launchers, manpad weapon, manpad magazine, manpad man classes] <ARRAY>
 *
 * Example:
 * ["OPF_F", east] call jmfsb_airdefence_fnc_sideKit
 */

params [["_faction", "", [""]], ["_side", sideUnknown, [sideUnknown]]];

if (isNil QGVAR(kitCache)) then { GVAR(kitCache) = createHashMap };

private _key = format ["%1_%2", _faction, _side];
private _hit = GVAR(kitCache) get _key;
if (!isNil "_hit") exitWith {_hit};

private _radar = "";
private _launchers = [];
private _manpad = "";

// --- what the module was told FOR THIS SIDE, if anything -------------------
(GVAR(classes) getOrDefault [str _side, ["", "", ""]]) params
    ["_setRadar", "_setLaunch", "_setManpad", ["_setMen", ""]];

if (_setRadar isNotEqualTo "") then { _radar = _setRadar };
if (_setLaunch isNotEqualTo "") then {
    _launchers = (_setLaunch splitString ",") apply { trim _x };
    _launchers = _launchers select {isClass (configFile >> "CfgVehicles" >> _x)};
};
if (_setManpad isNotEqualTo "") then { _manpad = _setManpad };

// The team's men, when the mission names them - a soldier class list, so a
// MANPAD team can be the faction's own AA specialists rather than riflemen
// handed a tube.
private _manpadMen = [];
if (_setMen isNotEqualTo "") then {
    _manpadMen = (_setMen splitString ",") apply { trim _x };
    _manpadMen = _manpadMen select {isClass (configFile >> "CfgVehicles" >> _x)};
};

// --- the faction's own, for anything still unset --------------------------
if (_radar isEqualTo "" || {_launchers isEqualTo []}) then {
    private _guns = [];
    {
        private _cls = configName _x;
        if (getNumber (_x >> "scope") != 2) then {continue};
        if (getText (_x >> "faction") != _faction) then {continue};

        // A radar is a sensor with no weapon; a launcher is a static that
        // shoots MISSILES at aircraft. Read off the config rather than a
        // class list, so this needs no maintenance as mods come and go.
        // EVERY matching static the faction fields, not the first one found.
        private _hasRadar = getNumber (_x >> "radarType") > 0;
        private _weapons = [] + getArray (_x >> "weapons");

        if (_cls isKindOf "StaticWeapon") then {
            switch ([_cls] call FUNC(aaKind)) do {
                case 2: { _launchers pushBackUnique _cls };
                case 1: { _guns pushBackUnique _cls };
            };
            if (_radar isEqualTo "" && _hasRadar && {_weapons isEqualTo []}) then {
                _radar = _cls;
            };
        };
    } forEach ("true" configClasses (configFile >> "CfgVehicles"));

    // A battery is LAUNCHERS. Gun turrets only step in when the faction
    // fields no missile system at all - and the log says so, because a ring
    // of ZUs where SAMs were expected should read as a choice, not a bug.
    if (_launchers isEqualTo [] && {_guns isNotEqualTo []}) then {
        _launchers = _guns;
        INFO_1("faction '%1' fields no missile AA - its batteries use gun systems",_faction);
    };
};

// --- the vanilla floor ----------------------------------------------------
private _fell = false;

if (_radar isEqualTo "") then {
    _radar = switch (_side) do {
        case west: {"B_Radar_System_01_F"};
        case independent: {"I_Radar_System_01_F"};
        default {"O_Radar_System_02_F"};
    };
    _fell = true;
};

if (_launchers isEqualTo []) then {
    // SAMs only - a battery is launchers, and the AAA guns that used to ride
    // in this list are how a "battery" came out as a ring of turrets.
    _launchers = switch (_side) do {
        case west: {["B_SAM_System_03_F"]};
        case independent: {["I_SAM_System_03_F"]};
        default {["O_SAM_System_04_F"]};
    };
    _fell = true;
};

if (_manpad isEqualTo "") then {
    _manpad = switch (_side) do {
        case west: {"launch_B_Titan_short_F"};
        case independent: {"launch_I_Titan_short_F"};
        default {"launch_O_Titan_short_F"};
    };
};

// Anything the mission set or the faction gave that does not actually exist is
// dropped here rather than at createVehicle, where it would be a null object
// and a site that silently never appeared.
if !(isClass (configFile >> "CfgVehicles" >> _radar)) then { _radar = "" };
_launchers = _launchers select {isClass (configFile >> "CfgVehicles" >> _x)};
if !(isClass (configFile >> "CfgWeapons" >> _manpad)) then { _manpad = "" };

private _mag = "";
if (_manpad isNotEqualTo "") then {
    _mag = (getArray (configFile >> "CfgWeapons" >> _manpad >> "magazines")) param [0, ""];
};

if (_fell) then {
    INFO_2("faction '%1' fields no air defence of its own - falling back to %2 hardware",_faction,_side);
};

private _kit = [_radar, _launchers, _manpad, _mag, _manpadMen];
GVAR(kitCache) set [_key, _kit];

_kit
