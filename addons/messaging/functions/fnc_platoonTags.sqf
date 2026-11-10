#include "script_component.hpp"
/*
 * Author: YonV
 * The unit's platoons as addressable tags: [callsign, [squad ids]].
 *
 * A PLATOON WAS NOT A TAG YOU COULD USE. FUNC(tagMatch) resolves a squad, a
 * job or a man - and a platoon is none of those, because no group is called
 * BANSHEE; the groups are BANSHEE 1-1 to 1-4. So "wake the whole mechanised
 * platoon" had to be four chips or four words typed out, on a net whose entire
 * point is that it is the platoon's.
 *
 * THE ORBAT ALREADY SAYS WHICH SQUADS ARE IN WHICH PLATOON - the platoon rows
 * the role screen draws its tabs from, and the ones
 * jmfsb_players_fnc_platoonNet reads for the radio. This is the same table,
 * read through jmfsb_groups_fnc_orbat so a unit that keeps its ORBAT in
 * TAC//PAC's database is addressable the same way, and a platoon that wants
 * to be addressable needs nothing added to it.
 *
 * MATCHED ON ANY OF ITS THREE NAMES - callsign, name, or net - because a man
 * typing a tag in a hurry types the word he says on the radio, and which of the
 * three that is depends on the mission. Spaces are noise, the same as
 * everywhere else a tag is compared.
 *
 * CACHED. The server asks FUNC(tagMatch) once per player per tagged message.
 * The cache is dropped when TAC//PAC hands a machine a new structure
 * (jmfsb_pac_fnc_takeServer, and the server's boot), which is the only time
 * the table can change.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[tag, [SQUAD IDS, upper-cased, spaces stripped]], ...] <ARRAY>
 *
 * Example:
 * private _platoons = [] call jmfsb_messaging_fnc_platoonTags
 *
 * Public: Yes
 */

if (!isNil QGVAR(platoonTagCache)) exitWith {+GVAR(platoonTagCache)};

private _out = [];
private _rows = if (!isNil "jmfsb_groups_fnc_orbat") then {([] call jmfsb_groups_fnc_orbat) # 1} else {[]};

{
    _x params ["", ["_name", ""], ["_callsign", ""], ["_net", ""], ["_squadsRaw", []]];
    private _squads = _squadsRaw apply {toUpper ((_x splitString " ") joinString "")};
    if (_squads isEqualTo []) then {continue};

    // Any of the three, and a repeat is skipped - a tag is looked up by
    // walking this list, so "BANSHEE" appearing as both callsign and net
    // answers the same squads either way.
    {
        private _tag = toUpper ((_x splitString " ") joinString "");
        if (_tag isNotEqualTo "" && {(_out findIf {(_x select 0) isEqualTo _tag}) isEqualTo -1}) then {
            _out pushBack [_tag, _squads];
        };
    } forEach [_callsign, _name, _net];
} forEach _rows;

GVAR(platoonTagCache) = _out;
+_out
