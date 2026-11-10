#include "script_component.hpp"
/*
 * Author: YonV
 * Narrows the player list to what was typed in the box above it.
 *
 * The filter is a plain substring, case-insensitive, matched against the name -
 * which is what everybody means by a search box and is faster than any cleverer
 * rule when the list is thirty names long.
 *
 * IT REBUILDS THROUGH THE PANEL'S OWN FUNCTION rather than hiding rows. The list
 * carries an index into admp_playerlist_playerArray in each row's VALUE, and
 * every action on this screen resolves its target through that index - so a list
 * filtered by any means other than a rebuild would point at the wrong man.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_filterList
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable ["admp_displayVar", displayNull];
if (isNull _display) exitWith {};

private _text = trim (ctrlText (_display displayCtrl IDC_ADMINPANEL_PLAYERLIST_FILTER));

// Nothing to do if the text has not actually changed - onKeyUp fires for arrow
// keys and modifiers too, and rebuilding a listbox on every one of them is what
// makes a search box feel like it is fighting you.
if (_text isEqualTo (missionNamespace getVariable [QGVAR(listFilter), ""])) exitWith {};

GVAR(listFilter) = _text;
[] call admp_fnc_updatePlayerList;
