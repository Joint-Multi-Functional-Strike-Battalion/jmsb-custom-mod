#include "script_component.hpp"
/*
 * Author: YonV
 * A checked order, on the server: books one delivery - the status, the plan
 * the board draws, the cooldown when it starts at the request - and launches
 * it at once (FUNC(launch)): its aircraft is virtual until tasked and is made
 * over the module now (user, 2026-11-02: "all support aircraft needs to be
 * virtual till tasked, then they spawn in at alt over the support module
 * location"). A delivery uses no respawn; only an aircraft lost does
 * (FUNC(lost)).
 *
 * WHAT GOES WITH IT is read here, once, from the request: the DROP HEIGHT
 * (an airdrop's pass, the module's unless picked) and the MARKING (the
 * module's Marking unless picked).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Task token <STRING>
 * 2: Delivery point ATL <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 * 4: Who asked <OBJECT>
 * 5: The cart, [[catalog index, count], ...] <ARRAY>
 * 6: The marking's class, over the MARKING slot - a card's colour (step 7,
 *    FUNC(srvThread)) <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "AIRDROP", _pos, _prm, _requester, [[0, 2]]] call jmfsb_support_logistics_fnc_deliver
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]], ["_requester", objNull, [objNull]], ["_cart", [], [[]]], ["_signalClass", "", [""]]];

// Two requesters can send for the same asset in the same second.
([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[_logic, "cannot take it - " + _why, "normal", _requester, false] call FUNC(say)};

private _height = [_prm, SLOT_DROP_ALT, 0, count DROP_ALT_TABLE - 1, DROP_ALT_TABLE, _logic getVariable [QGVAR(dropHeight), DEF_DROP_HEIGHT]] call EFUNC(support_air,readParam);
private _markIdx = [_prm, SLOT_MARK, 0, count MARK_CLASSES - 1] call EFUNC(support_air,readParam);
private _signal = if (_markIdx isEqualTo 0) then {_logic getVariable [QGVAR(signalClass), ""]} else {MARK_CLASSES select _markIdx};
if (_signalClass isNotEqualTo "") then {_signal = _signalClass};

private _names = [_logic getVariable [QGVAR(catalog), []], _cart] call FUNC(cartNames);

_logic setVariable [QGVAR(status), STATUS_LAUNCHING, true];
_logic setVariable [QGVAR(plan), [[_pos, _task]], true];
// COOLDOWN STARTS AT THE REQUEST: for everything ordered, delivered or not.
if ((_logic getVariable [QGVAR(cooldownTrigger), COOLDOWN_AT_END]) isEqualTo COOLDOWN_AT_START) then {
    private _wait = (_logic getVariable [QGVAR(cooldown), 0]) + count _names * (_logic getVariable [QGVAR(itemCooldown), 0]);
    _logic setVariable [QGVAR(readyAt), CBA_missionTime + _wait, true];
};

[_logic, format ["copy %1 by %2 to %3 - airborne now", [_names] call FUNC(countLine), toLower _task, mapGridPosition _pos], "high", _requester] call FUNC(say);

// Next frame, so the WILCO and this line are in the thread before WHEELS UP.
[FUNC(launch), [_logic, _task, _pos, _cart, _height, _signal, _requester]] call CBA_fnc_execNextFrame;
