#include "script_component.hpp"
/*
 * Author: YonV
 * Sets a shared net's subscription level for THIS player and keeps it.
 *
 * Written to the player's profile, not the mission: which nets a man wants
 * ringing is a personal preference that should survive tonight's restart,
 * exactly like his colour scheme. Net NAMES are stable across missions in a
 * way thread ids never are, which is why this persists and the per-thread
 * override - FUNC(follow) - deliberately does not.
 *
 * Arguments:
 * 0: Net name, as the mailbox setting spells it, e.g. "HQ" <STRING>
 * 1: Level - 0 alert, 1 muted <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Fires", 1] call jmfsb_messaging_fnc_setNetLevel
 *
 * Public: Yes
 */

params [["_net", "", [""]], ["_level", 0, [0]]];

_net = trim _net;
if (_net == "") exitWith {};

GVAR(netLevels) set [_net, 0 max (_level min 1)];

profileNamespace setVariable [QGVAR(netLevels), GVAR(netLevels) toArray false];
saveProfileNamespace;
