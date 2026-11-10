#include "script_component.hpp"
/*
 * Author: YonV
 * The marker card's PLACE (and Enter in its text box): the marker the card
 * shows, made through FUNC(mark) on the picked channel, and the card closed.
 *
 * A marker of his own that the card was opened on is replaced: the old one
 * deleted, the new one made - the game's dialog edits a marker the same way.
 * The icon and colour are kept for the next card; size and direction are
 * this marker's only, and a new card opens at normal size, pointing north.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The marker made, "" for none <STRING>
 *
 * Example:
 * [] call jmfsb_maptools_fnc_markerCardPlace
 *
 * Public: No
 */

private _state = uiNamespace getVariable [QGVAR(cardState), createHashMap];
if (count _state isEqualTo 0) exitWith {""};

private _type = _state getOrDefault ["type", MARK_TYPE];
private _color = _state getOrDefault ["color", MARK_COLOR];
private _edit = _state getOrDefault ["edit", ""];

uiNamespace setVariable [QGVAR(cardType), _type];
uiNamespace setVariable [QGVAR(cardColor), _color];

if (_edit isNotEqualTo "") then {
    [_edit] call FUNC(markerDelete);
};

private _marker = [
    _state getOrDefault ["pos", []],
    _type,
    _color,
    _state getOrDefault ["text", ""],
    _state getOrDefault ["channel", MARK_CHANNEL],
    _state getOrDefault ["size", CARD_SIZE_NORMAL],
    _state getOrDefault ["dir", 0]
] call FUNC(mark);

[] call FUNC(markerCardClose);

_marker
