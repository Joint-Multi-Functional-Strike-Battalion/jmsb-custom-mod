#include "script_component.hpp"
/*
 * Author: YonV
 * Takes the marker card down, and its preview off the map. With a display,
 * only when the card stands on that display - the vanilla map closing must
 * not take down a card standing on the tablet.
 *
 * Arguments:
 * 0: The display going away, displayNull for any <DISPLAY> (optional, default displayNull)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_maptools_fnc_markerCardClose
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

private _card = uiNamespace getVariable [QGVAR(card), controlNull];
private _cardDisplay = ctrlParent _card;

if (!isNull _display && _cardDisplay isNotEqualTo _display) exitWith {};

ctrlDelete _card;
uiNamespace setVariable [QGVAR(card), controlNull];
uiNamespace setVariable [QGVAR(cardState), createHashMap];
GVAR(cardPreview) = [];
