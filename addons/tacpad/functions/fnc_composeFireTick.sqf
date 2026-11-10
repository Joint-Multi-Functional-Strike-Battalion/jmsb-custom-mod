#include "script_component.hpp"
/*
 * Author: YonV
 * The composer's footprint, polled (user, 2026-11-02; FUNC(composeFire)):
 * every COMPOSE_FIRE_POLL seconds while a card's preview stands, on either
 * host, it checks that the composer is still writing that root card; once it
 * is gone - sent, cancelled, a reply, the reader shut - the footprint is taken
 * off the map (EFUNC(support,cardPreview) with nothing) and the poll stops.
 * A change of card or address is not this poll's: the pane's next draw asks
 * again and the core clears what it drew.
 *
 * ONE POLL AT A TIME. Every answer arms it; an armed poll is not armed again.
 *
 * Arguments:
 * 0: Only arm the poll, if it is not armed <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [true] call jmfsb_tacpad_fnc_composeFireTick
 *
 * Public: No
 */

params [["_arm", false, [false]]];

if (_arm) exitWith {
    if (GVAR(composeFireArmed)) exitWith {};
    GVAR(composeFireArmed) = true;
    [{[] call FUNC(composeFireTick)}, [], COMPOSE_FIRE_POLL] call CBA_fnc_waitAndExecute;
};

GVAR(composeFireArmed) = false;
if (GVAR(composeFire) isEqualTo []) exitWith {};

private _open = !isNull (uiNamespace getVariable [QGVAR(reader), displayNull]) && GVAR(composeOn) && GVAR(composeThread) isEqualTo "" && GVAR(composeTemplate) isNotEqualTo "";
if (_open) exitWith {[true] call FUNC(composeFireTick)};

GVAR(composeFireKey) = [];
GVAR(composeFire) = [];
if (!isNil QEFUNC(support,cardPreview)) then {[] call EFUNC(support,cardPreview)};
