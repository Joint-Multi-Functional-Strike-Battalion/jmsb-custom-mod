#include "script_component.hpp"
/*
 * Author: JMSB
 * The net name of the platoon a squad belongs to, from the unit's ORBAT.
 *
 * WHY THIS EXISTS. The MR plan is written per PLATOON, not per squad (user,
 * 2026-09-01: "4 plt nets ever one sees then squad net only a squad sees") -
 * four channels for a task force of fourteen elements. fn_getRadioChannel
 * matches a channel by name against the group id, so "NOMAD 2-3" finds nothing
 * and would land on the detachment default; this is what it asks next.
 *
 * THE ORBAT ALREADY SAYS WHICH SQUADS ARE IN WHICH PLATOON - the platoon rows
 * the role screen draws its tabs from - so a platoon that wants a radio net
 * adds one property to the tab it already has. Read through
 * jmfsb_groups_fnc_orbat, so the rows are the database's when TAC//PAC holds
 * the ORBAT there and the mission's Dynamic_Groups otherwise.
 *
 * ONE TABLE. The platoon a squad belongs to, and the net on that platoon.
 * There was a "shared radio nets" table asked first; it is gone, and so is
 * the idea (user, 2026-09-09: "noi fucking shared nets ... acre and tfar tab
 * only for fucking radios"). Radio channels are the ACRE plan and the net
 * plan (game voice); messaging nets are mailboxes on the messaging tab.
 *
 * A platoon with no net, a unit with no platoons, or a squad in no platoon all
 * answer "" and leave the caller on its default.
 *
 * Arguments:
 * 0: Squad name <STRING> - the group id, any case
 *
 * Return Value:
 * Net name, upper-cased, or "" <STRING>
 *
 * Example:
 * ["NOMAD 2-3"] call jmfsb_players_fnc_platoonNet  // "NOMAD"
 *
 * Public: No
 */

params [["_squad", "", [""]]];

if (_squad isEqualTo "") exitWith {""};
if (isNil "jmfsb_groups_fnc_orbat") exitWith {""};
_squad = toUpper _squad;

([] call jmfsb_groups_fnc_orbat) params ["", "_platoons"];

// rows, the index of the net in a row, the index of the squad list in a row
private _fnc_lookup = {
    params ["_rows", "_netAt", "_squadsAt"];
    private _hit = "";
    {
        private _net = _x param [_netAt, ""];
        if (!(_net isEqualType "") || _net isEqualTo "") then {continue};
        private _squads = _x param [_squadsAt, []];
        if !(_squads isEqualType []) then {continue};
        if (_squad in (_squads apply {toUpper _x})) exitWith {_hit = toUpper _net};
    } forEach _rows;
    _hit
};

// THE PLATOON'S NET, AND NOTHING ELSE. There was a "shared nets" table asked
// first - rows pairing squads across a platoon boundary onto one net - and it
// is gone (user, 2026-09-09: "no fucking shared nets ... if there is acre use
// the acre tab to configure all radios"). A squad's channel is the radio
// plan's business: ACRE matches this name against an MR channel label, the
// net plan reads the squad's own row.
private _net = [_platoons, 3, 4] call _fnc_lookup;

_net
