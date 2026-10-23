#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: the server (or FUNC(netAdd) itself) refused something about an
 * RTO net - said in words, with the busy tone, the way a refused call is
 * (FUNC(callFailed)).
 *
 * Arguments:
 * 0: Reason - one of the REASON_* of the RTO nets <STRING>
 * 1: The name or id it was about <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["badName", "x"] call jmfsb_voice_fnc_netFailed
 *
 * Public: No
 */

params [["_reason", "", [""]], ["_name", "", [""]]];

private _text = switch (_reason) do {
    case REASON_NOT_RTO: {"RTO nets are the RTO's and the admin's to make."};
    case REASON_BAD_NAME: {format ["'%1' will not do as a net name: %2 to %3 letters, digits, spaces or dashes, and not a name already in use.", _name, CUSTOM_NAME_MIN, CUSTOM_NAME_MAX]};
    case REASON_TAKEN: {format ["%1 is already a net.", toUpper _name]};
    case REASON_FULL: {format ["No room for another RTO net: %1 at once.", GVAR(customNetsMax)]};
    case REASON_NO_CHANNEL: {"No voice channel is left for a new net."};
    default {format ["%1: no such RTO net.", toUpper _name]};
};

["RADIO", _text] call EFUNC(notify,notify);
["busy", ""] call FUNC(playCue);
