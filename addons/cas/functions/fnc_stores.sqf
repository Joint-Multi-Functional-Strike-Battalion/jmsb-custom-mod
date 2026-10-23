#include "script_component.hpp"
/*
 * Author: JMSB
 * What the airframe is actually carrying, in the words painted on the side of
 * it - one entry per store, heaviest first.
 *
 * THE PAGE USED TO OFFER CATEGORIES AND THE AIRCRAFT CARRIES OBJECTS. "BOMB /
 * MISSILE / ROCKET / GUN" is a taxonomy: it is the same five words over a
 * Reaper, a Bayraktar and a Buzzard, it cannot tell a GBU from a Scalpel when
 * an airframe has both, and it offers three kinds nothing aboard has ever
 * carried. A man calling a strike knows what his drone is hung with and asks
 * for THAT, so this reads the airframe's own stores and the page offers those.
 *
 * READ OFF THE CONFIG, NOT OFF THE AIRCRAFT, because the row is drawn while
 * the asset is still on the ground somewhere it does not exist - the aircraft
 * is created when the run is ordered. The class is what both ends share, so
 * the list the page shows and the list FUNC(task) indexes into are the same
 * list from the same read. An object may be passed instead and its live
 * loadout is used, which is what makes the answer honest for an airframe whose
 * pylons were rewritten after it spawned.
 *
 * BOTH PLACES ORDNANCE HIDES ARE READ. Turret magazines cover the gun and the
 * fixed-armament airframes; the pylon component covers everything with a
 * dynamic loadout, where the class's own magazines[] is empty and the default
 * fit lives one attachment at a time under Pylons.
 *
 * AIR-TO-AIR IS NOT ORDNANCE A SECTION IN CONTACT CAN USE. Anything the engine
 * marks as lockable on aircraft ONLY is dropped, so a UCAV carrying two
 * Falchions does not offer them to a man asking for a strike on a treeline.
 *
 * Arguments:
 * 0: Airframe class, or the aircraft itself <STRING|OBJECT>
 *
 * Return Value:
 * One entry per store, heaviest first <ARRAY>
 * 0: Magazine class <STRING>
 * 1: What to call it on the page <STRING>
 *
 * Public: No
 */

params [["_src", "", ["", objNull]]];

private _cls = if (_src isEqualType "") then {_src} else {typeOf _src};
if (_cls isEqualTo "") exitWith {[]};
if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith {[]};

// ONE READ PER CLASS, EVER. The support page redraws on a two-second poll and
// on every press; walking a plane's turret tree and pylon component each time
// is a config trawl for an answer that cannot change. A live object is never
// cached - its pylons are exactly the thing that can.
private _cache = missionNamespace getVariable [QGVAR(storesCache), createHashMap];
if (_src isEqualType "" && {_cls in _cache}) exitWith {+(_cache get _cls)};

private _mags = [];

if (_src isEqualType objNull) then {
    // magazinesAllTurrets is [magazine, turret, [rounds, ...]] and includes the
    // pylons, because a pylon is a magazine on the turret that owns it.
    {_mags pushBack (_x param [0, ""])} forEach (magazinesAllTurrets _src);
} else {
    private _cfg = configFile >> "CfgVehicles" >> _cls;

    _mags append (getArray (_cfg >> "magazines"));

    // Turrets nest - a gunner turret can carry a commander turret carrying its
    // own weapon - so the tree is walked rather than its first level read.
    private _fnc_turrets = {
        params ["_node"];
        {
            _mags append (getArray (_x >> "magazines"));
            [_x] call _fnc_turrets;
        } forEach configProperties [_node >> "Turrets", "isClass _x", true];
    };
    [_cfg] call _fnc_turrets;

    // The dynamic-loadout airframes: magazines[] is empty and the fit that
    // comes out of the factory is one attachment per pylon.
    private _pylons = _cfg >> "Components" >> "TransportPylonsComponent" >> "Pylons";
    {
        private _att = getText (_x >> "attachment");
        if (_att isNotEqualTo "") then {_mags pushBack _att};
    } forEach configProperties [_pylons, "isClass _x", true];

    // Some classes leave the pylons empty and name the standard fit as a
    // preset instead. The first preset is the one createVehicle gives us.
    if (_mags isEqualTo []) then {
        private _presets = configProperties [_cfg >> "Components" >> "TransportPylonsComponent" >> "Presets", "isClass _x", true];
        if (_presets isNotEqualTo []) then {
            _mags append (getArray ((_presets select 0) >> "attachment"));
        };
    };
};

// Heaviest first, and it is the same ranking FUNC(fireAt) picks AUTO with -
// one list, so the order the page reads down is the order the run would have
// chosen for itself.
private _seen = createHashMap;

{
    private _mag = _x;
    if (_mag isEqualTo "") then {continue};

    private _cfgMag = configFile >> "CfgMagazines" >> _mag;
    if !(isClass _cfgMag) then {continue};

    private _rounds = 1 max getNumber (_cfgMag >> "count");

    if (_mag in _seen) then {
        // Two pylons of the same store are one line on the page with twice the
        // rounds on it, not two identical rows the player has to tell apart.
        private _e = _seen get _mag;
        _e set [1, (_e select 1) + _rounds];
        continue;
    };

    private _ammo = getText (_cfgMag >> "ammo");
    if (_ammo isEqualTo "") then {continue};

    private _cfgAmmo = configFile >> "CfgAmmo" >> _ammo;
    private _r = CAS_RANK find (toLower getText (_cfgAmmo >> "simulation"));
    if (_r < 0) then {continue};

    // airLock 2 is the engine's "locks aircraft and nothing else" - a missile
    // that cannot be asked to hit the ground is not a CAS store.
    if (getNumber (_cfgAmmo >> "airLock") isEqualTo 2) then {continue};

    private _name = getText (_cfgMag >> "displayNameShort");
    if (_name isEqualTo "") then {_name = getText (_cfgMag >> "displayName")};
    if (_name isEqualTo "") then {_name = _mag};

    // The page gives this column a third of the row. A full config display
    // name runs to "GBU-12 Paveway II Laser Guided Bomb", which draws over the
    // steppers beside it; the head of the name is the part that identifies it.
    if (count _name > 18) then {_name = (_name select [0, 17]) + "."};

    _seen set [_mag, [_r, _rounds, _name]];
} forEach _mags;

private _rows = [];
// Over a hashmap _x is the KEY (the magazine) and _y the value.
{
    _y params ["_r", "_rounds", "_name"];
    _rows pushBack [_r, format ["%1 x%2", _name, _rounds], _x];
} forEach _seen;

// sort on the leading rank; the name is the tie-break, so two airframes of the
// same class always publish the same list in the same order - the page sends
// back an INDEX and an order that wandered would fly the wrong store.
_rows sort true;

private _out = _rows apply {[_x select 2, _x select 1]};

if (_src isEqualType "") then {
    _cache set [_cls, _out];
    missionNamespace setVariable [QGVAR(storesCache), _cache];
};

+_out
