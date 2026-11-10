#include "script_component.hpp"
/*
 * Author: YonV
 * The ID of the platoon a squad belongs to, from the unit's ORBAT.
 *
 * WHY THIS AND NOT FUNC(platoonNet). That one answers with the platoon's
 * messaging NET, which is what the MR plan is written against. This answers
 * with the platoon's ID - the first element of the platoon row - because the
 * long-range plan is keyed by platoon, not by net: two platoons can share a
 * net and still want different LR channels, and a platoon can have an LR
 * channel and no net at all.
 *
 * Read through jmfsb_groups_fnc_orbat, so the rows are the database's when
 * TAC//PAC holds the ORBAT there and the mission's Dynamic_Groups otherwise.
 *
 * A unit with no platoons, or a squad in no platoon, answers "" and leaves the
 * caller on its default.
 *
 * Arguments:
 * 0: Squad name <STRING> - the group id, any case
 *
 * Return Value:
 * The platoon id as the ORBAT spells it, or "" <STRING>
 *
 * Example:
 * ["NOMAD 2-3"] call jmfsb_players_fnc_platoonOf  // "Plt2"
 *
 * Public: No
 */

params [["_squad", "", [""]]];

if (_squad isEqualTo "") exitWith {""};
if (isNil "jmfsb_groups_fnc_orbat") exitWith {""};
_squad = toUpper _squad;

([] call jmfsb_groups_fnc_orbat) params ["", "_platoons"];

private _hit = "";
{
    // [id, name, callsign, net, [squads]] - the id is what the LR plan names.
    private _id = _x param [0, ""];
    if (!(_id isEqualType "") || _id isEqualTo "") then {continue};
    private _squads = _x param [4, []];
    if !(_squads isEqualType []) then {continue};
    if (_squad in (_squads apply {toUpper _x})) exitWith {_hit = _id};
} forEach _platoons;

_hit
