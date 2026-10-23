#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts an aircraft down near a point.
 *
 * A HELICOPTER lands on an invisible pad set on the clearest patch within
 * LZ_SEARCH of the point - the engine lands on the nearest pad, and without
 * one picks its own spot, which is the roof the section is standing beside.
 * The mode is the engine's: "GET IN" waits engine running for boarders,
 * "GET OUT" for passengers leaving, "LAND" shuts down.
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
 *
 * Return Value:
 * Landing ordered <BOOL>
 *
 * Example:
 * [_veh, _pos, "GET OUT"] call jmfsb_support_air_fnc_landAt
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_pos", [], [[]]], ["_mode", "LAND", [""]]];

if (!alive _veh || {_pos isEqualTo []}) exitWith {false};

if (_veh isKindOf "Helicopter") exitWith {
    private _lz = _pos findEmptyPosition [0, LZ_SEARCH, typeOf _veh];
    if (_lz isEqualTo []) then {_lz = +_pos};

    private _old = _veh getVariable [QGVAR(pad), objNull];
    if (!isNull _old) then {deleteVehicle _old};
    private _pad = createVehicle [LZ_PAD, _lz, [], 0, "CAN_COLLIDE"];
    _veh setVariable [QGVAR(pad), _pad];

    [_veh, _lz, "NORMAL"] call FUNC(moveTo);
    _veh land _mode;
    true
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
