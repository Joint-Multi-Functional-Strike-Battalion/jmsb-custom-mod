#include "script_component.hpp"
/*
 * Author: JMSB
 * Picks what the hack does when it completes - the HACK app's ACTIONS row:
 * HACK_ACTION_SPOOF ("spoof") where FUNC(canSpoof) allows it, anything else
 * the kind's own (TAP a product, DISABLE a drone). Refuses while a hack is
 * running, as picking the device and the product do.
 *
 * Arguments:
 * 0: Action - "spoof", or "tap" / "" for the kind's own <STRING>
 *
 * Return Value:
 * The action now set <STRING>
 *
 * Example:
 * ["spoof"] call jmfsb_hacking_fnc_tabletSelectAction
 *
 * Public: No
 */

params [["_action", HACK_ACTION_DEFAULT, [""]]];

private _session = GVAR(session);
if (_session getOrDefault ["running", false]) exitWith {_session getOrDefault ["action", HACK_ACTION_DEFAULT]};

private _set = [HACK_ACTION_DEFAULT, HACK_ACTION_SPOOF] select (_action isEqualTo HACK_ACTION_SPOOF && {[_session] call FUNC(canSpoof)});
_session set ["action", _set];
_set
