#include "script_component.hpp"
/*
 * Author: JMSB
 * Steps the tablet's RADIO app to its previous or next tab - NETS, CALLS,
 * MANAGE - for the tab keys (numpad 7 / 8) while the tablet is up and RADIO is
 * the open app. The tab is the app's own (jmfsb_tacpad_apps_radioTab in
 * uiNamespace), and the app is redrawn on it next frame, as its tab row does.
 *
 * Arguments:
 * 0: Step, -1 or +1 <NUMBER>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [1] call jmfsb_devices_fnc_tabletRadioTab
 *
 * Public: No
 */

params [["_step", 1, [0]]];

private _tab = uiNamespace getVariable [QEGVAR(tacpad_apps,radioTab), RADIO_APP_TABS select 0];
private _at = (RADIO_APP_TABS find _tab) max 0;
uiNamespace setVariable [QEGVAR(tacpad_apps,radioTab), RADIO_APP_TABS select ((_at + _step + count RADIO_APP_TABS) mod count RADIO_APP_TABS)];
[{["radio"] call EFUNC(tacpad,openApp)}] call CBA_fnc_execNextFrame;
true
