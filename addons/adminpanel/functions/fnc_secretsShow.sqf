#include "script_component.hpp"
/*
 * Author: JMSB
 * The server's answer to the SECRETS dialog (jmfsb_common_fnc_secretStatus,
 * review R4): per row SET and the last four characters, or NOT SET. Taken only
 * from the server.
 *
 * Arguments:
 * 0: [name, set, last four] per secret <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[["livekitKey", true, "x9Qa"]]] call jmfsb_adminpanel_fnc_secretsShow
 *
 * Public: No
 */

params [["_rows", [], [[]]]];

if !([] call EFUNC(common,fromServer)) exitWith {};
private _display = uiNamespace getVariable [QGVAR(secretsDisplay), displayNull];
if (isNull _display) exitWith {};

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent"];
{
    _x params [["_name", "", [""]], ["_set", false, [false]], ["_tail", "", [""]]];
    private _row = SECRET_KEYS find _name;
    if (_row < 0) then {continue};
    private _said = if (_set) then {["SET", "SET  ..." + _tail] select (_tail isNotEqualTo "")} else {"NOT SET"};
    (_display displayCtrl (IDC_ADMINSECRETS_STATUS + _row)) ctrlSetStructuredText parseText format [
        "<t font='RobotoCondensed' size='0.75' align='right' color='%1'>%2</t>",
        ([_ink, _accent] select _set) call BIS_fnc_colorRGBAtoHTML, _said
    ];
} forEach _rows;
