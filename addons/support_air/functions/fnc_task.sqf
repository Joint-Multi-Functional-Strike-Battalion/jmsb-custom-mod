#include "script_component.hpp"
/*
 * Author: JMSB
 * Takes one order from TAC//SUPPORT and either sends it to the server or
 * says why not - the "task" code of provider "air".
 *
 * RUNS ON THE REQUESTER'S MACHINE (the core calls it there). Everything that
 * can be refused is refused here, with the reason on his screen; what is
 * accepted is flown on the server, which owns every aircraft this addon
 * creates, through QGVAR(order).
 *
 * NO GRID IS ALLOWED ONLY WHERE "ON ME" MAKES SENSE. A PICKUP or an EXTRACT
 * without a point comes to the requester; everything else is aimed at a
 * place and the screen already holds CONFIRM until one is set.
 *
 * THE COOLDOWN IS THIS ADDON'S, NOT THE CORE'S. An air asset is turned round
 * when the aircraft is home, not when the order is given, so the module
 * starts its own clock at the end of the sortie (FUNC(finish)) and this
 * returns no cooldown to the core.
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: Task token, or "rtb" <STRING>
 * 2: Target position, [] for none <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 *
 * Return Value:
 * 0: Accepted <BOOL>
 * 1: Why not, or what was sent <STRING>
 * 2: Core cooldown, always 0 <NUMBER>
 *
 * Example:
 * ["air:0", "SAD", getPosATL player, []] call jmfsb_support_air_fnc_task
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {
    WARNING_1("task: no asset behind id '%1'",_assetId);
    [false, "that asset is gone", 0]
};

private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
private _kind = _logic getVariable [QGVAR(kind), ""];

// RECALL IS PASSED THROUGH WHENEVER SOMETHING IS OUT - an asset you want home
// is busy.
if (_task isEqualTo TASK_RTB) exitWith {
    // Idle covers turning round and spent too - nothing is out to recall.
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_IDLE) exitWith {
        [false, format ["%1 is at base - nothing to recall", _callsign], 0]
    };
    [QGVAR(order), [_logic, TASK_RTB, [], _prm, player]] call CBA_fnc_serverEvent;
    INFO_1("%1 recalled",_callsign);
    [true, format ["%1 returning to base", _callsign], 0]
};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[false, _why, 0]};

// The token must be one THIS asset offers - the screen only shows those, but
// a request can come from anywhere.
private _offered = ([_assetId, [_logic] call FUNC(entityRow)] call FUNC(tasks)) apply {_x select 0};
if !(_task in _offered) exitWith {
    INFO_3("task refused for %1 - '%2' is not one of %3",_callsign,_task,_offered);
    [false, format ["%1 does not fly %2", _callsign, _task], 0]
};

if (_pos isEqualTo []) then {
    if (_task in [TASK_PICKUP, TASK_EXTRACT, TASK_LIFT]) then {_pos = getPosATL player};
};
if (_pos isEqualTo []) exitWith {[false, "no target grid", 0]};
_pos = [_pos select 0, _pos select 1, 0];

// What the screen should already have made sure of - a request can come from
// anywhere.
if (_task in [TASK_LIFT, TASK_SLING] && {([_prm, SLOT_LZ] call FUNC(readPoint)) isEqualTo []}) exitWith {
    [false, format ["%1 needs %2", _task, ["an LZ", "a set-down point"] select (_task isEqualTo TASK_SLING)], 0]
};
if (_task isEqualTo TASK_HELOCAST && {!surfaceIsWater _pos}) exitWith {
    [false, format ["%1 casts over water only - %2 is land", _callsign, mapGridPosition _pos], 0]
};

// The QRF squad must exist before the aircraft is sent for it.
if (_kind isEqualTo KIND_QRF && {([_logic] call FUNC(qrfSquad)) isEqualTo []}) exitWith {
    [false, format ["%1 has no squad to send", _callsign], 0]
};

[QGVAR(order), [_logic, _task, _pos, +_prm, player]] call CBA_fnc_serverEvent;

[true, "", 0]
