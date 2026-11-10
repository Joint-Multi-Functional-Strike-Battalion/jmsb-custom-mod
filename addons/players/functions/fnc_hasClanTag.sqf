#include "script_component.hpp"
/*
 * Author: YonV
 * Does this player's profile name start with their squad tag?
 *
 * Not "are they in a squad" - the question the caller is actually asking is
 * whether the name it is about to show has a tag stuck on the front of it that
 * should come off. A man in a squad who does not put the tag in his name has
 * nothing to trim.
 *
 * Arguments:
 * 0: Unit <OBJECT> (optional, default player)
 *
 * Return Value:
 * The profile name carries the tag <BOOL>
 *
 * Example:
 * if (call jmfsb_players_fnc_hasClanTag) then {...};
 *
 * Public: Yes
 */

params [["_unit", player, [objNull]]];

private _tag = [_unit] call FUNC(getClanTag);
if (_tag isEqualTo "") exitWith {false};

toLower (profileName select [0, count _tag]) isEqualTo toLower _tag
