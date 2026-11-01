#include "script_component.hpp"
/*
 * Author: JMSB
 * A SECRETS row's SET (code review R4): sends what is typed in that row to the
 * server alone (jmfsb_common_fnc_secretSet, which checks the logged-in admin
 * and answers with the status), then empties the field so it is not left on
 * the screen. An empty field clears that secret.
 *
 * Arguments:
 * 0: Row, 0-3 <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [1] call jmfsb_adminpanel_fnc_secretsSet
 *
 * Public: No
 */

params [["_row", 0, [0]]];

private _display = uiNamespace getVariable [QGVAR(secretsDisplay), displayNull];
if (isNull _display || _row < 0 || _row >= IDC_ADMINSECRETS_ROWS) exitWith {};

private _edit = _display displayCtrl (IDC_ADMINSECRETS_EDIT + _row);
[SECRET_KEYS select _row, ctrlText _edit] remoteExecCall [QEFUNC(common,secretSet), ADMIN_SERVER];
_edit ctrlSetText "";
(_display displayCtrl (IDC_ADMINSECRETS_STATUS + _row)) ctrlSetStructuredText parseText "<t font='RobotoCondensed' size='0.75' align='right'>SENDING</t>";
playSound "3DEN_notificationDefault";
