#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the observer a support card names (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING step 6 and D6) - the CALL FOR FIRE's Observer line.
 * The corrections are made along his line to the target (FUNC(readOrder)),
 * and his follow-ups are taken like the issuer's (FUNC(srvFollowUp)).
 *
 * MATCHED AS THE CARD CARRIES IT. The composer fills the line with the
 * sender's group id (autoFill ownCallsign); a man may type a name instead. So
 * a player on the server is the observer when his group id or his name is the
 * line's text, upper-case either way - every man of the named group, the
 * group's leader first. A card with no Observer line, or an empty one, names
 * nobody.
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 * 1: Its root message <HASHMAP>
 *
 * Return Value:
 * 0: The Observer line's text, "" none <STRING>
 * 1: The players it names, leaders first <ARRAY of OBJECTs>
 *
 * Example:
 * ([_thread, _root] call jmfsb_support_fnc_observer) params ["_name", "_men"]
 *
 * Public: Yes
 */

params [["_thread", createHashMap, [createHashMap]], ["_message", createHashMap, [createHashMap]]];

private _cardId = _message getOrDefault ["templateId", _thread getOrDefault ["rootTemplateId", ""]];
private _at = OBSERVER_FIELDS findIf {(_x select 0) isEqualTo _cardId};
if (_at < 0) exitWith {["", []]};

private _text = (createHashMapFromArray (_message getOrDefault ["payload", []])) getOrDefault [(OBSERVER_FIELDS select _at) select 1, ""];
if !(_text isEqualType "") exitWith {["", []]};
_text = trim _text;
if (_text isEqualTo "") exitWith {["", []]};

private _want = toUpper _text;
private _men = allPlayers select {
    alive _x && {(toUpper groupId (group _x)) isEqualTo _want || (toUpper name _x) isEqualTo _want}
};
private _leaders = _men select {(leader group _x) isEqualTo _x};

[_text, _leaders + (_men - _leaders)]
