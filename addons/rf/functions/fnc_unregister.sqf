#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_unregister: takes a node out of the registry. Its links vanish on the
 * next tick, and every slice that named it changes then.
 *
 * Arguments:
 * 0: Node id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["node_a"] call jmfsb_rf_fnc_unregister
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

if (!isServer) exitWith {
    [QGVAR(unregister), [_id]] call CBA_fnc_serverEvent;
};

GVAR(nodes) deleteAt _id;
GVAR(sky) deleteAt _id;
