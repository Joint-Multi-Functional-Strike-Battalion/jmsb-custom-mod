#include "script_component.hpp"
/*
 * Author: YonV
 * The player's squad tag, from their squad.xml, or "" if they have none.
 *
 * THIS WAS CALLED AND NEVER WRITTEN. FUNC(unit_getVariables) and
 * FUNC(unit_getName) both called jmfsb_players_fnc_getClanTag /
 * jmfsb_players_fnc_hasClanTag, which existed nowhere - so a name lookup threw
 * rather than returning a name. Written here against BI's own squad data.
 *
 * DEFENSIVE ON PURPOSE. squadParams returns nothing at all for a player with
 * no squad.xml, and the shape of what it does return is not worth trusting
 * blind - so anything unexpected reads as "no tag", and the callers fall back
 * to the untouched profile name. A wrong tag would silently mangle every
 * player's name; no tag simply leaves it alone.
 *
 * Arguments:
 * 0: Unit <OBJECT> (optional, default player)
 *
 * Return Value:
 * The squad tag <STRING>
 *
 * Example:
 * private _tag = call jmfsb_players_fnc_getClanTag;
 *
 * Public: Yes
 */

params [["_unit", player, [objNull]]];

if (isNull _unit) exitWith {""};

// OFF UNLESS ASKED FOR - see initSettings.inc.sqf. squadParams is not a free
// read: it makes the engine resolve the unit's squad, logo included, and a logo
// that is not on disk is then retried on every rendered frame. The switch is
// checked here rather than at the call sites so there is exactly one place that
// can reach the squad system at all.
if !(missionNamespace getVariable [QGVAR(enableClanTag), false]) exitWith {""};

private _params = squadParams _unit;
if (!(_params isEqualType []) || {_params isEqualTo []}) exitWith {""};

private _squad = _params param [0, []];
if (!(_squad isEqualType []) || {_squad isEqualTo []}) exitWith {""};

// The nick is the short form - the bracketed thing people put in front of
// their name. Anything that is not a string, or is long enough to be the
// squad's full title rather than its tag, is refused.
private _nick = _squad param [1, "", [""]];
if (_nick isEqualTo "" || {count _nick > 12}) exitWith {""};

_nick
