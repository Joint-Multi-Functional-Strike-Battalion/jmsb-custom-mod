#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_antiship_fnc_moduleAntiShip

Description:
    Sites the coastal anti-ship batteries so the mission maker does not have to -
    or get to - know where they are (user, 2026-10-03). The module jmfsb had,
    brought back: DIVINER dropped it because DIVINER has no TAORs, and the
    launcher's own doc still says so. JMSB runs ALiVE, which does.

    WHO GETS ONE. Every ALiVE commander whose side the players are not on, each
    inside its own TAOR (EFUNC(adapter_alive,taorFor)). No side field: the enemy
    is whoever the mission's commanders and player slots say it is (D59). With
    no ALiVE commanders the module's own area is the ground, for the first side
    the players are not on.

    WHAT A BATTERY IS. A surface search radar on the shoreline - the only part
    that can see the sea - and its launchers inland behind it, sited where they
    CANNOT see the water (the README's design: kill the radar and the battery is
    blind). Each piece brings itself on line through its own Extended_Init, the
    same as one placed by hand; this only finds the ground and crews it.

    NOT PROFILED, ON PURPOSE. Profiling virtualises - ALiVE deletes what it is
    handed and spawns it again near players - and a launcher's clock and a
    radar's tracks live on the object. EFUNC(adapter_alive,profileIgnore) is the
    documented opt-out, as air defence uses it. OPCOM still garrisons the site:
    the launcher registers it as an objective itself.

Parameters:
    0: The module logic <OBJECT>
    1: Synchronised units <ARRAY>
    2: Activated <BOOL>

Returns:
    None

Author:
    YonV
---------------------------------------------------------------------------- */
params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};

private _batteries = round ((_logic getVariable ["batteriesPerSide", 1]) max 0);
private _launchers = round ((_logic getVariable ["launchersPerBattery", 2]) max 1);
private _radars = round ((_logic getVariable ["radarsPerBattery", 1]) max 0);
if (_batteries < 1) exitWith {
    INFO("anti-ship module placed with 0 batteries per side - nothing sited");
};

// The module's own area: the ground when there is no ALiVE to ask.
(_logic getVariable ["objectArea", [0, 0, 0, false, 0]]) params [["_a", 0], ["_b", 0]];
private _area = [getPosATL _logic, (_a max _b) max AS_LAUNCH_MAX];

private _run = {
    params ["_batteries", "_launchers", "_radars", "_area"];

    private _players = call EFUNC(common,playerSides);
    private _jobs = [];     // [side, taor markers, blacklist markers]

    if (!isNil QEFUNC(adapter_alive,commanders) && {missionNamespace getVariable [QEGVAR(adapter_alive,ready), false]}) then {
        {
            _x params ["_side"];
            if (_side in [west, east, independent]
                && {!(_side in _players)}
                && {_jobs findIf {(_x select 0) isEqualTo _side} < 0}) then {
                ([_side] call EFUNC(adapter_alive,taorFor)) params ["_taor", "_black"];
                _jobs pushBack [_side, _taor, _black];
            };
        } forEach (call EFUNC(adapter_alive,commanders));
    };

    // No commanders to read: the module's area, for whoever the players oppose.
    private _useArea = _jobs isEqualTo [];
    if (_useArea) then {
        private _side = ([east, independent, west] select {!(_x in _players)}) param [0, east];
        _jobs pushBack [_side, [], []];
    };

    // The nearest sea from a spot: eight bearings probed outward, closest water
    // wins. [] when there is none within AS_SITE_COAST.
    private _asSeaNear = {
        params ["_p"];
        private _best = [];
        private _bestD = AS_SITE_COAST + 1;
        for "_dir" from 0 to 315 step 45 do {
            for "_r" from AS_SITE_PROBE to AS_SITE_COAST step AS_SITE_PROBE do {
                private _q = _p getPos [_r, _dir];
                if (surfaceIsWater _q) exitWith {
                    if (_r < _bestD) then {_bestD = _r; _best = _q};
                };
            };
        };
        _best
    };

    {
        _x params ["_side", "_taor", "_black"];

        // AN EMPTY TAOR IS THE WHOLE MAP, ALiVE's convention - so the ground is
        // the markers when there are some, else a ring: the module's area, or
        // the map.
        private _ground = createHashMap;
        if (_taor isEqualTo []) then {
            if (_useArea) then {
                _ground set ["centre", _area select 0];
                _ground set ["maxRange", _area select 1];
            } else {
                _ground set ["centre", [worldSize / 2, worldSize / 2, 0]];
                _ground set ["maxRange", worldSize * AS_WORLD_REACH];
            };
        };

        // THE RADAR, ON THE COAST. Scored by how close the sea is and by
        // height - a mast on a headland sees further than one on a beach.
        // Inland ground scores nothing and is dropped after, not trusted.
        private _coast = +_ground;
        {
            _coast set _x;
        } forEach [
            ["footprint", AS_RADAR_FOOT], ["maxSlope", AS_SITE_SLOPE], ["separation", AS_SITE_SPREAD],
            ["blacklist", _black], ["samples", AS_SITE_SAMPLES],
            ["score", {
                params ["_p"];
                private _s = [_p] call _asSeaNear;
                if (_s isEqualTo []) then {AS_SITE_REJECT} else {
                    (AS_SITE_COAST - (_p distance2D _s)) + getTerrainHeightASL _p
                }
            }]
        ];
        private _sites = ([_taor, _batteries, _coast] call EFUNC(common,findSite))
            select {([_x] call _asSeaNear) isNotEqualTo []};

        if (_sites isEqualTo []) then {
            WARNING_2("anti-ship: no coast inside %1's TAOR %2 - no battery for that side",_side,_taor);
            continue;
        };
        if (count _sites < _batteries) then {
            WARNING_3("anti-ship: only %1 of %2 coastal sites inside %3's TAOR",count _sites,_batteries,_side);
        };

        {
            private _site = _x;
            private _sea = [_site] call _asSeaNear;
            private _placed = [];

            // the radars: the first on the site, any more along the same shore
            private _radarSpots = [_site];
            if (_radars > 1) then {
                _radarSpots append ([[], _radars - 1, createHashMapFromArray [
                    ["centre", _site], ["minRange", AS_LAUNCH_SPREAD], ["maxRange", AS_SITE_COAST],
                    ["footprint", AS_RADAR_FOOT], ["maxSlope", AS_SITE_SLOPE], ["separation", AS_LAUNCH_SPREAD],
                    ["blacklist", _black], ["losTo", [_sea]]
                ]] call EFUNC(common,findSite));
            };
            if (_radars < 1) then {_radarSpots = []};

            // THE LAUNCHERS, INLAND AND BLIND TO THE SEA - that is what makes
            // the radar worth hunting.
            private _launchSpots = [[], _launchers, createHashMapFromArray [
                ["centre", _site], ["minRange", AS_LAUNCH_MIN], ["maxRange", AS_LAUNCH_MAX],
                ["footprint", AS_LAUNCH_FOOT], ["maxSlope", AS_SITE_SLOPE], ["separation", AS_LAUNCH_SPREAD],
                ["blacklist", _black], ["losDenied", [_sea]]
            ]] call EFUNC(common,findSite);
            if (count _launchSpots < _launchers) then {
                WARNING_3("anti-ship: only %1 of %2 launcher sites behind %3",count _launchSpots,_launchers,mapGridPosition _site);
            };

            {
                _x params ["_class", "_spots"];
                {
                    private _v = createVehicle [_class, _x, [], 0, "CAN_COLLIDE"];
                    _v setDir (_x getDir _sea);
                    _v setVectorUp surfaceNormal _x;
                    createVehicleCrew _v;
                    // THE CREW TAKES THE BATTERY'S SIDE. Both classes are OPFOR
                    // statics, so their own crew is OPFOR; a west or independent
                    // battery joins it to a group of its own side, before the
                    // launcher's init reads its side a frame from now.
                    (crew _v) joinSilent (createGroup [_side, true]);
                    if (!isNil QEFUNC(adapter_alive,profileIgnore)) then {
                        [_v] call EFUNC(adapter_alive,profileIgnore);
                    };
                    _placed pushBack _v;
                } forEach _spots;
            } forEach [[QGVAR(radar), _radarSpots], [QGVAR(launcher), _launchSpots]];

            INFO_3("anti-ship battery sited for %1 at %2: %3 pieces",_side,mapGridPosition _site,count _placed);
        } forEach _sites;
    } forEach _jobs;
};

// ALiVE's commanders come up after the module runs. Wait for the adapter; if it
// gives up - a mission without commanders - site in the module's own area
// instead of siting nothing.
//
// One path without ALiVE (user, 2026-11-02: "works with or without" - "same
// as not loaded"): no ALiVE loaded, nothing to wait for, so the module's own
// area as soon as the mission runs; ALiVE loaded with no commanders, the same
// branch once the adapter gives up (its give-up replaced this module's own
// AS_ALIVE_WAIT timeout). _run travels in the arguments: a hook runs later, where
// this function's locals are gone.
private _job = [_run, [_batteries, _launchers, _radars, _area]];
private _without = {
    params ["_run", "_args"];
    ["Anti-ship", "using the module's own area"] call EFUNC(common,aliveLoaded);
    [{time > 0}, _run, _args] call CBA_fnc_waitUntilAndExecute;
};

if (isNil QEFUNC(adapter_alive,whenReady)) exitWith {
    _job call _without;
};

[{
    params ["_run", "_args"];
    _args call _run;
}, _job, _without] call EFUNC(adapter_alive,whenReady);
