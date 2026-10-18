#include "..\script_component.hpp"
/*
 * Author: JMSB
 * An engagement's moment has come - the interceptor's flight time to the
 * threat has run out. Roll the intercept chance (the unit's Site override,
 * else the setting). A hit asks the machine that fired the round to delete it
 * with a small blast (FUNC(kill)); a miss frees the threat for any unit that
 * still has time.
 *
 * Arguments:
 * 0: Threat (T_* in script_component.hpp) <ARRAY>
 *
 * Return Value:
 * Intercepted <BOOL>
 *
 * Example:
 * [_threat] call jmfsb_adsite_fnc_resolve
 *
 * Public: No
 */

params ["_threat"];

private _rec = GVAR(units) get (_threat select T_UNIT);
private _chance = GVAR(interceptChance);
if (!isNil "_rec" && {(_rec select U_CHANCE) >= 0}) then { _chance = _rec select U_CHANCE };

if (random 1 >= _chance) exitWith {
    _threat set [T_UNIT, ""];
    GVAR(stats) set ["misses", (GVAR(stats) get "misses") + 1];
    false
};

private _owner = _threat select T_OWNER;
private _id = _threat select T_ID;
if (!isNull _owner) then {
    if (local _owner) then {
        [_id] call FUNC(kill);
    } else {
        [QGVAR(kill), [_id], _owner] call CBA_fnc_targetEvent;
    };
};
GVAR(stats) set ["intercepts", (GVAR(stats) get "intercepts") + 1];
true
