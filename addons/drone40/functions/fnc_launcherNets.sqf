#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the fill a launcher's own RF nodes hold - every [net, key] of every
 * node whose holder he is (his radios, as the radio adapters register them),
 * without the nodes of this addon. Read through jmfsb_rf_fnc_nodesFor.
 *
 * Arguments:
 * 0: Launcher <OBJECT>
 *
 * Return Value:
 * Fill <ARRAY of [STRING, STRING]>
 *
 * Example:
 * [player] call jmfsb_drone40_fnc_launcherNets
 *
 * Public: No
 */

params [["_launcher", objNull, [objNull]]];

private _fill = [];
{
    {
        _fill pushBackUnique _x;
    } forEach (_x select 3);
} forEach ([_launcher, [OWNER_TAG]] call EFUNC(rf,nodesFor));

_fill
