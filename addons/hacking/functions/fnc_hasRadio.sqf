#include "script_component.hpp"
/*
 * Author: JMSB
 * Is this man carrying a radio worth taking off his body?
 *
 * The test is the item's own SIMULATION rather than a list of classnames, so
 * a vanilla ItemRadio, an ACRE PRC-152 and our MPU5 (an ItemRadio) all answer
 * the same way and no radio mod needs a compatibility entry here. Assigned items
 * and inventory both count - a spare handset in a vest is still a handset.
 *
 * Arguments:
 * 0: The man <OBJECT>
 *
 * Return Value:
 * Carrying a radio <BOOL>
 *
 * Example:
 * [_unit] call jmfsb_hacking_fnc_hasRadio
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {false};

private _carried = (assignedItems _unit) + (items _unit);

(_carried findIf {
    (getText (configFile >> "CfgWeapons" >> _x >> "simulation")) isEqualTo "ItemRadio"
}) > -1
