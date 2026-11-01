#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: who sent the order now running, if he may task this asset at all
 * (review S6). The requester is the sending machine's own player
 * (EFUNC(common,sender)), never a unit from the arguments; the asset must be
 * a fires module on the board, and he must pass the tasking tag gate
 * (EFUNC(support,canTask)). A refusal is told to him alone.
 *
 * Call it at the top of the remote-executed function, before any delayed
 * work: there the sender is no longer known.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The requester, objNull when refused <OBJECT>
 *
 * Example:
 * private _requester = [_logic] call jmfsb_support_fires_fnc_requester
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

([] call EFUNC(common,sender)) params ["_owner", "_unit"];
if (isNull _unit) exitWith {
    WARNING_1("requester: refused - machine %1 has no player",_owner);
    objNull
};
if !(_logic in GVAR(entities)) exitWith {
    WARNING_2("requester: refused - %1 from %2 is not a fires module on the board",_logic,_unit);
    objNull
};

([_unit] call EFUNC(support,canTask)) params ["_may", "_why"];
if (!_may) exitWith {
    WARNING_2("requester: refused - %1 may not task: %2",_unit,_why);
    [format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], false, _why, _unit] call EFUNC(support,ack);
    objNull
};

_unit
