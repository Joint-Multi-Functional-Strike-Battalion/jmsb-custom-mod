#include "script_component.hpp"
/*
 * Author: JMSB
 * One leg of a path: the signal one radio would receive from another, by
 * ACRE's own propagation model (acre_sys_signal_fnc_getSignalCore - terrain,
 * antennas, the lot), cached for a few seconds so a busy net does not ask the
 * model the same question every time a receiver is evaluated.
 *
 * Arguments:
 * 0: Frequency in MHz <NUMBER>
 * 1: Transmitter power in mW <NUMBER>
 * 2: Receiving radio id <STRING>
 * 3: Transmitting radio id <STRING>
 *
 * Return Value:
 * [quality 0..1, signal dBm] <ARRAY>
 *
 * Example:
 * [30, 5000, "ACRE_PRC152_ID_1", "ACRE_PRC117F_ID_2"] call jmfsb_radio_mesh_fnc_edge
 *
 * Public: No
 */
params ["_freq", "_power", "_rx", "_tx"];

private _key = format ["%1|%2|%3", _tx, _rx, _freq];
private _hit = GVAR(edgeCache) get _key;
if (!isNil "_hit" && {diag_tickTime - (_hit select 0) <= MESH_EDGE_TTL}) exitWith { _hit select 1 };

private _core = [_freq, _power, _rx, _tx] call acre_sys_signal_fnc_getSignalCore;
if (!(_core isEqualType []) || {count _core < 2}) then { _core = [0, MESH_NO_SIGNAL] };
GVAR(edgeCache) set [_key, [diag_tickTime, _core]];
_core
