#include "script_component.hpp"
/*
 * Author: YonV
 * Each side's drone supply caches: real crates, in that side's own TAOR, away
 * from each other and from its objectives' centres - a cache under the guns
 * of the thing it supplies is not a target, it is scenery.
 *
 * They are deliberately NOT marked and NOT hinted here. Finding them is what
 * the intel economy is for.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

// NO ZONES, NO CACHES. A cache is supply for the drones flying over a zone;
// with nowhere being patrolled there is nothing for it to supply.
if ((missionNamespace getVariable [QGVAR(zones), []]) isEqualTo []) exitWith {};

private _want = round GVAR(cachesPerSide);
if (_want <= 0) exitWith {};

// A stack of paper boxes, as directed - supply that looks like supply, not an
// ammo crate begging to be looted. Falls back to the old crate rather than
// silently placing nothing if the prop's addon is not in this mod set.
private _class = ["Land_PaperBox_01_small_stacked_F", "Box_Syndicate_Ammo_F"] select
    (parseNumber !(isClass (configFile >> "CfgVehicles" >> "Land_PaperBox_01_small_stacked_F")));

// The registry the intel economy reads - EFUNC(hacking,intelHint) points hint
// circles at the nearest hostile cache. Server-side list of the live objects;
// readers filter dead ones themselves.
if (isNil QGVAR(caches)) then { GVAR(caches) = [] };

// EVERY SIDE THAT HAS ZONES, once each. The commander list this walked is gone
// and a side with three zones is still one side with one cache allowance.
private _sides = [];
{ _sides pushBackUnique (_x # 0) } forEach (missionNamespace getVariable [QGVAR(zones), []]);

{
    private _side = _x;

    // INSIDE THE GROUND BEING PATROLLED, spread across it. Caches used to be
    // scattered over a side's whole ALiVE TAOR and kept clear of its objectives
    // - unmarked, unhinted, and the intel economy's job to find. A zone is that
    // ground now, and FUNC(findSite) already takes a ring rather than markers,
    // so the zone's own centre and radius are the search area.
    private _zones = ([_side] call FUNC(zonesFor));
    if (_zones isEqualTo []) then {continue};

    // The side's allowance split over its zones, at least one each until it runs
    // out - three caches and four zones is three zones with a cache, not four
    // zones with none.
    private _left = _want;
    private _per = (ceil (_want / count _zones)) max 1;
    private _placed = 0;

    {
        if (_left <= 0) exitWith {};
        _x params ["", "_centre", "_radius"];

        private _spots = [[], _per min _left, createHashMapFromArray [
            ["centre", _centre],
            ["maxRange", _radius],
            ["footprint", 3],
            ["clearRadius", 4],
            ["separation", 600],
            ["nearRoad", 300]
        ]] call EFUNC(common,findSite);

        {
            private _cache = createVehicle [_class, _x, [], 0, "CAN_COLLIDE"];
            _cache setDir random 360;
            _cache setVariable [QGVAR(cacheSide), _side, true];
            _cache addEventHandler ["Killed", {
                params ["_cache"];
                [_cache] call FUNC(cacheDown);
            }];
            GVAR(caches) pushBack _cache;
            // THE COMMANDER'S CACHE, NOT A PROP. Registered as an objective it
            // gets garrisoned and retaken - see antiship for the same reasoning.
            // Guarded; without ALiVE it is just a cache.
            if (!isNil QEFUNC(adapter_alive,registerSite)) then {
                [_side, format ["cache_%1", mapGridPosition _x], _x, 100, 70] call EFUNC(adapter_alive,registerSite);
            };
        } forEach _spots;

        _left = _left - count _spots;
        _placed = _placed + count _spots;
    } forEach _zones;

    INFO_2("side %1: %2 cache(s)",_side,_placed);
} forEach _sides;
