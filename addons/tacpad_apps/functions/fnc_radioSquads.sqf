#include "script_component.hpp"
/*
 * Author: JMSB
 * Every squad callsign a custom net can be given (user, 2026-10-22: "allow
 * rtos to add custom channels"): the distinct callsigns of the voice contacts
 * and the player's own group, upper-cased and sorted - the form a custom
 * net's squads list carries them in on the server (jmfsb_voice_customPub).
 *
 * Arguments:
 * 0: The voice contacts, as jmfsb_voice_fnc_contacts answers <ARRAY>
 *
 * Return Value:
 * Callsigns <ARRAY of STRINGs>
 *
 * Example:
 * private _squads = [_ctx get "contacts"] call jmfsb_tacpad_apps_fnc_radioSquads
 *
 * Public: No
 */

params [["_contacts", [], [[]]]];

private _squads = [];
private _me = call CBA_fnc_currentUnit;
if (!isNull _me) then {
    private _own = toUpper trim groupId group _me;
    if (_own isNotEqualTo "") then {_squads pushBackUnique _own};
};
{
    private _callsign = toUpper trim (_x param [2, ""]);
    if (_callsign isNotEqualTo "") then {_squads pushBackUnique _callsign};
} forEach _contacts;

_squads sort true;
_squads
