#include "script_component.hpp"
/*
 * Author: YonV
 * Sends one drone to look at a place - the recon rung of the reaction ladder.
 *
 * Obeys the same ceiling everything else does, so a side whose supply caches
 * have been hit answers a discovery with less than one whose have not. That
 * is the payoff for the raid, made visible at the moment it matters.
 *
 * Arguments:
 * 0: Side <SIDE>
 * 1: Where to look <ARRAY>
 *
 * Return Value:
 * A drone was sent <BOOL>
 *
 * Example:
 * [east, getPosATL player] call jmfsb_uas_fnc_respondTo
 */

params [["_side", sideUnknown, [sideUnknown]], ["_pos", [], [[]]]];

if (_side isEqualTo sideUnknown || {_pos isEqualTo []}) exitWith {false};

// THE SIDE'S WHOLE ALLOWANCE, which is the sum of what its modules asked for
// and not a ceiling of its own any more - one module is one patrol. The supply
// cap is applied per patrol, the same way FUNC(planPatrols) applies it.
//
// The PRUNED count - the raw list let freshly-dead drones block a
// reaction-ladder dispatch until the next planning tick.
private _have = [_side] call FUNC(livePatrols);
private _allowed = 0;
{
    _allowed = _allowed + ([_side, _x # 5] call FUNC(ceilingFor));
} forEach ([_side] call FUNC(zonesFor));

if (_have >= _allowed) exitWith {
    INFO_2("%1 wanted to send a drone but all %2 of its airframes are up",_side,_allowed);
    false
};

// A DRONE ANSWERS INSIDE ITS OWN ZONES. The reaction ladder and the QRF hand
// this whatever position the noise came from, and a side sending an airframe
// across the map to a contact it has drawn no zone near is the sighting this
// rule exists to prevent - it was a TAOR test before and the zones say the same
// thing more directly.
private _zones = [_side] call FUNC(zonesFor);
private _inside = _zones findIf {
    _x params ["", "_centre", "_radius"];
    (_pos distance2D _centre) <= _radius
};

if (_zones isNotEqualTo [] && _inside < 0) exitWith {
    INFO_1("%1 keeps its drones inside its own patrol zones",_side);
    false
};

// No faction: FUNC(topUp) falls through to a UAV belonging to the side, which is
// what an unset Drone Class on the module does too.
private _faction = "";

[_side, _faction, _pos] call FUNC(topUp)
