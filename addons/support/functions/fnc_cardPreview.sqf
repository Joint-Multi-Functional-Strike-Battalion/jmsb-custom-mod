#include "script_component.hpp"
/*
 * Author: YonV
 * Client: what a support card being composed WOULD get, before SEND (user,
 * 2026-11-02; first for a call for fire to a battery) - one verdict line for
 * the composer and the footprint on this player's map. The card's values are
 * read the server's way (FUNC(readOrder), on a thread of this player's own)
 * and handed to the provider's optional "cardPreview" code, [assetId, order]
 * -> [ok, line, marker specs]. The specs are drawn as local markers
 * (FUNC(pinMarker)), named under the thread pins' prefix so a pin never takes
 * them for a marker the player placed; the last ones go each call.
 *
 * Asked by the composer on a change of the card, never per frame. Nothing is
 * decided here: the server reads the card again when it is filed and answers
 * as it will. Called with no box, no card or a provider without the hook, it
 * only clears what it drew.
 *
 * Arguments:
 * 0: The TO line, mailbox ids separated by commas <STRING> (optional, default "")
 * 1: Card id <STRING> (optional, default "")
 * 2: The card's values, field key -> value <HASHMAP> (optional, default empty)
 *
 * Return Value:
 * [ok, line], [] when there is nothing to say <ARRAY>
 *
 * Example:
 * ["B:SUPPORT:fires:0", "callforfire", _values] call jmfsb_support_fnc_cardPreview
 *
 * Public: Yes
 */

#define CARD_PREVIEW_PIN QGVAR(pin_cff_%1)

params [["_to", "", [""]], ["_cardId", "", [""]], ["_values", createHashMap, [createHashMap]]];

if (!hasInterface) exitWith {[]};

{deleteMarkerLocal _x} forEach (missionNamespace getVariable [QGVAR(cardPreviewDrawn), []]);
GVAR(cardPreviewDrawn) = [];

// The first support asset's mailbox on the TO line.
private _head = count SUPPORT_BOX_PREFIX;
private _assetId = "";
{
    private _box = trim _x;
    if ((toUpper (_box select [0, _head])) isEqualTo SUPPORT_BOX_PREFIX) exitWith {_assetId = _box select [_head]};
} forEach (_to splitString ",");
if (_assetId isEqualTo "" || _cardId isEqualTo "") exitWith {[]};

([_assetId] call FUNC(provider)) params ["_kind", "_decl"];
if (_kind isEqualTo "" || !("cardPreview" in _decl)) exitWith {[]};

private _thread = createHashMapFromArray [["issuerUid", getPlayerUID player], ["rootTemplateId", _cardId]];
private _message = createHashMapFromArray [["templateId", _cardId], ["payload", _values toArray false]];
private _order = [_thread, _message] call FUNC(readOrder);

private _answer = [_assetId, _order] call (_decl get "cardPreview");
if (isNil "_answer" || {!(_answer isEqualType [])} || {count _answer < 2}) exitWith {[]};
_answer params [["_ok", true, [true]], ["_line", "", [""]], ["_specs", [], [[]]]];
if (_line isEqualTo "") exitWith {[]};

{
    private _name = format [CARD_PREVIEW_PIN, _forEachIndex];
    [_name, _x] call FUNC(pinMarker);
    GVAR(cardPreviewDrawn) pushBack _name;
} forEach (_specs select {_x isEqualType []});

[_ok, _line]
