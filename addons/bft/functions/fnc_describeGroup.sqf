#include "script_component.hpp"
/*
 * Author: YonV
 * One line of admin readout for a group: what it is, whether it is transmitting,
 * how it is drawn, and the nets it is on. Everything an admin needs to answer
 * "why can I not see them" without opening a single menu.
 *
 * Arguments:
 * 0: Group <GROUP>
 *
 * Return Value:
 * Description <STRING>
 *
 * Example:
 * [group player] call jmfsb_bft_fnc_describeGroup
 *
 * Public: No
 */

params [["_group", grpNull, [grpNull]]];

if (isNull _group) exitWith {""};

private _visible = _group getVariable [QGVAR(visible), GVAR(autoEnable) isEqualTo 2];
private _type = _group getVariable [QGVAR(type), "inf"];
private _color = _group getVariable [QGVAR(color), [side _group, true] call BIS_fnc_sideColor];
private _tx = _group getVariable [QGVAR(encryptCodes), [str side _group]];
private _rx = _group getVariable [QGVAR(decryptCodes), []];

format [
    "%1 (%2, %3 units) %4 | %5/%6 | tx: %7 | rx: %8",
    groupId _group,
    side _group,
    count units _group,
    ["OFF", "ON"] select _visible,
    _type,
    _color,
    ([_tx joinString ",", "-"] select (_tx isEqualTo [])),
    ([_rx joinString ",", "-"] select (_rx isEqualTo []))
]
