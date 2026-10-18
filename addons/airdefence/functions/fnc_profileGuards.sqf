#include "script_component.hpp"
/*
 * Author: JMSB
 * Hands an AA base's guard groups to ALiVE, once ALiVE can take them.
 *
 * Every jmfsb spawn is profiled - but only through the adapter, and only once
 * it says ALiVE is up. A module runs at mission init, long before that, so a
 * not-yet-ready adapter means "wait for it", and the guards are profiled when
 * its ready event fires. No adapter at all (ALiVE not loaded) means there is
 * nothing to hand them to: they stay live, and the RPT says so. The same holds
 * if ALiVE is loaded but never comes up - the guards simply stay live.
 *
 * Arguments:
 * 0: The guard groups <ARRAY of GROUP>
 *
 * Return Value: None
 *
 * Example:
 * [_groups] call jmfsb_airdefence_fnc_profileGuards
 *
 * Public: No
 */

params [["_groups", [], [[]]]];

private _live = _groups select {!isNull _x && {(units _x) isNotEqualTo []}};
if (_live isEqualTo []) exitWith {};

if (isNil QEFUNC(adapter_alive,profileGroup)) exitWith {
    INFO_1("AA base: no ALiVE adapter - %1 guard group(s) stay live",count _live);
};

if !(missionNamespace getVariable [QEGVAR(adapter_alive,ready), false]) exitWith {
    // One-shot: the adapter raises ready once, and this handler goes with it.
    [QEGVAR(adapter_alive,ready), {
        [_thisType, _thisId] call CBA_fnc_removeEventHandler;
        [_thisArgs] call FUNC(profileGuards);
    }, _live] call CBA_fnc_addEventHandlerArgs;
    INFO_1("AA base: %1 guard group(s) wait for ALiVE before profiling",count _live);
};

private _done = {
    ([_x] call EFUNC(adapter_alive,profileGroup)) isNotEqualTo []
} count _live;

INFO_2("AA base: %1 of %2 guard group(s) profiled",_done,count _live);
