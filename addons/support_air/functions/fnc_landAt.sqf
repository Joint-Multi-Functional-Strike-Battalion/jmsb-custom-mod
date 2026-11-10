#include "script_component.hpp"
/*
 * Author: YonV
 * Puts an aircraft down near a point.
 *
 * A HELICOPTER lands on the clearest patch within LZ_SEARCH of the point,
 * flown in and put down by this addon's own flight control (2026-11-05,
 * FUNC(heliTake) - modelled on how Simplex Support Services pilots a
 * helicopter; no code of it used): a hover HELI_LAND_HOVER m over the pad,
 * then a damped touchdown. The mode says what the engine does once it is
 * down: "GET IN" and "GET OUT" keep it running for boarders and passengers
 * leaving, "LAND" shuts down. It stays put until its next order.
 *
 * A FIXED-WING AIRCRAFT goes to the nearest airfield to the point - the
 * map's own, or a carrier-style dynamic one - and lands there. Only a synced
 * aircraft is ever brought home this way; one made from a class is removed
 * over the module instead.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Where, ATL <ARRAY>
 * 2: Landing mode for a helicopter <STRING> (optional, default "LAND")
 * 3: A helicopter's pad is moved clear of anything in its rotor's way
 *    (FUNC(clearSpot), 2026-11-02) - false for a stand on a deck or a roof
 *    <BOOL> (optional, default true)
 *
 * Return Value:
 * Landing ordered <BOOL>
 *
 * Example:
 * [_veh, _pos, "GET OUT"] call jmfsb_support_air_fnc_landAt
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_pos", [], [[]]], ["_mode", "LAND", [""]], ["_clear", true, [true]]];

if (!alive _veh || {_pos isEqualTo []}) exitWith {false};

if ([_veh] call EFUNC(support,isRotary)) exitWith {
    private _lz = _pos findEmptyPosition [0, LZ_SEARCH, typeOf _veh];
    if (_lz isEqualTo []) then {_lz = +_pos};

    // A CLEAR PAD FOR THE ROTOR (2026-11-02, the user's RPT 07:37:53: RAVEN's
    // rotor wrecked on the ground, nothing hit it): findEmptyPosition fits the
    // body, not the rotor disc. A pad with something standing into it is moved
    // to the nearest clear spot within LZ_SEARCH, said in the RPT
    // (FUNC(clearSpot)); none clear - the pad stays, said too.
    if (_clear) then {
        ([_veh, _lz, 0, LZ_SEARCH] call FUNC(clearSpot)) params ["_spot", "_blockers"];
        if (_blockers isEqualTo []) exitWith {};
        if (_spot isEqualTo []) exitWith {
            WARNING_3("'%1' lands at %2 with %3 in its rotor's way - no clear spot near",typeOf _veh,mapGridPosition _lz,_blockers joinString ", ");
        };
        WARNING_4("'%1' landing at %2 blocked for the rotor by %3 - moved %4 m",typeOf _veh,mapGridPosition _lz,_blockers joinString ", ",round (_lz distance2D _spot));
        _lz = _spot;
    };

    [_veh, _lz, HELI_LAND_HOVER, true, _mode isNotEqualTo "LAND", HELI_APPROACH_SPEED, format ["landing to %1", toLower _mode]] call FUNC(heliTake)
};

// THE NEAREST AIRFIELD. Static airports are numbered by the world config:
// 0 is the main one (ilsPosition), 1.. the SecondaryAirports in order.
// Dynamic ones (carriers) are objects.
private _world = configFile >> "CfgWorlds" >> worldName;
private _fields = [[0, getArray (_world >> "ilsPosition")]];
{
    _fields pushBack [_forEachIndex + 1, getArray (_x >> "ilsPosition")];
} forEach ("true" configClasses (_world >> "SecondaryAirports"));

private _best = -1;
private _bestD = 1e10;
{
    _x params ["_id", "_at"];
    if (count _at >= 2) then {
        private _d = _pos distance2D [_at select 0, _at select 1];
        if (_d < _bestD) then {
            _bestD = _d;
            _best = _id;
        };
    };
} forEach _fields;
{
    private _d = _pos distance2D _x;
    if (_d < _bestD) then {
        _bestD = _d;
        _best = _x;
    };
} forEach ((allAirports param [1, []]) select {_x isEqualType objNull});

if (_best isEqualTo -1) exitWith {
    WARNING_1("'%1' has no airfield on this map to land at",typeOf _veh);
    false
};

_veh landAt _best;
true
