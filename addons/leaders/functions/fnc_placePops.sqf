#include "script_component.hpp"
/*
 * Author: YonV
 * Internet pops: rugged-server props in the asymmetric TAOR's settlements.
 *
 * Extra places to plug in that the comms towers do not cover, so a player
 * working a town has something to reach for. They join the hacking tower pool
 * by classname, which is all the wiring they need.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

private _want = round GVAR(pops);
if (_want <= 0) exitWith {};

// TWO PROPS, AND THE GROUND PICKS WHICH. A pop indoors is a server box in a
// back room; a pop outdoors is infrastructure somebody parked at the kerb.
// One prop for both looked absurd at one end or the other - a shipping
// container in a living room, or a desktop server alone in a field.
//
// WHATEVER IS PLACED IS HACKABLE BECAUSE OF ITS TAG, not its class - see
// EFUNC(hacking,nearestTower). The old rugged terminals were never in the
// hackable-class setting, so every pop this addon ever placed was scenery.
private _fnc_firstClass = {
    params ["_list"];
    private _c = "";
    { if (isClass (configFile >> "CfgVehicles" >> _x)) exitWith { _c = _x } } forEach _list;
    _c
};

private _inCls = [["Land_PortableServer_01_olive_F",
                   "Land_PortableServer_01_black_F",
                   "Land_Laptop_unfolded_F"]] call _fnc_firstClass;

private _outCls = [["Land_Cargo20_EMP_F",
                    "Land_RuggedTerminal_01_communications_hub_F",
                    "RuggedTerminal_01_communications_hub_F",
                    "Land_RuggedTerminal_01_communications_F",
                    "RuggedTerminal_01_communications_F"]] call _fnc_firstClass;

if (_inCls isEqualTo "" && _outCls isEqualTo "") exitWith {
    INFO("no pop prop in this mod set - no internet pops");
};

// ALiVE's TAOR and settlement clusters - or, without ALiVE, the jmfsb_taor
// markers and the map's own towns (user, 2026-11-02).
([GVAR(asymSide)] call EFUNC(common,groundFor)) params ["_taor", "_black"];
private _clusters = call EFUNC(common,settlements);

private _at = [];
{
    _x params ["_cpos", "_csize"];
    if (count _at >= _want) exitWith {};
    if (_taor isNotEqualTo [] && {(_taor findIf {_cpos inArea _x}) < 0}) then {continue};
    if ((_black findIf {_cpos inArea _x}) > -1) then {continue};

    // INDOORS FIRST. A network node lives in a building, and a room is a
    // better place to hide one than a street corner - a player has to go in
    // after it. The prop follows the ground: server box inside, container out.
    private _pos = [];
    private _cls = "";
    private _inside = false;

    if (_inCls isNotEqualTo "") then {
        // Enterable, intact, on ground the commander holds, and clear of the
        // pops already placed.
        private _houses = (nearestObjects [_cpos, ["House"], _csize max 150]) select {
            private _h = _x;
            damage _h < 0.5
            && {(_h buildingPos -1) isNotEqualTo []}
            && {_taor isEqualTo [] || {(_taor findIf {_h inArea _x}) > -1}}
            && {(_black findIf {_h inArea _x}) < 0}
            && {_at findIf {_x distance2D (getPosATL _h) < 300} < 0}
        };

        if (_houses isNotEqualTo []) then {
            private _house = selectRandom _houses;
            private _bps = _house buildingPos -1;
            if (_bps isNotEqualTo []) then {
                _pos = selectRandom _bps;
                _cls = _inCls;
                _inside = true;
            };
        };
    };

    // nothing enterable here - the kerb version, on open ground
    if (_pos isEqualTo [] && _outCls isNotEqualTo "") then {
        private _spots = [[], 1, createHashMapFromArray [
            ["centre", _cpos],
            ["maxRange", _csize max 120],
            ["footprint", 2],
            ["separation", 300],
            ["avoid", _at],
            ["avoidRadius", 300],
            ["blacklist", _black]
        ]] call EFUNC(common,findSite);
        if (_spots isNotEqualTo []) then {
            _pos = _spots select 0;
            _cls = _outCls;
        };
    };

    if (_pos isEqualTo []) then {continue};

    private _p = createVehicle [_cls, [0, 0, 0], [], 0, "CAN_COLLIDE"];
    if (isNull _p) then {continue};
    // setPosATL after creation, not createVehicle's own position: a building
    // position is a point on a floor, and the spawn placement would slide the
    // prop to the terrain under the house instead of leaving it upstairs.
    _p setPosATL _pos;
    _p setDir random 360;

    // Tagged, so the hacking addon can tell a pop from a real comms tower -
    // being seen working one has consequences a tower does not.
    _p setVariable [QGVAR(pop), true, true];

    // ON THE MAP. A pop nobody can find is content nobody meets. Indoor ones
    // say so - the marker is on the building, and the player still has to
    // find the room.
    private _m = createMarker [format [QGVAR(popMarker_%1), count _at], _pos];
    _m setMarkerTypeLocal "loc_Transmitter";
    _m setMarkerColorLocal "ColorOrange";
    // the last call is the global one - it carries the whole marker
    _m setMarkerText (["NET POP", "NET POP (INSIDE)"] select _inside);

    _at pushBack _pos;
} forEach _clusters;

INFO_3("%1 internet pop(s) placed - indoors '%2', outdoors '%3'",count _at,_inCls,_outCls);
