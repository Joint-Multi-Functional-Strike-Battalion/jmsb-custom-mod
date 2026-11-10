#include "script_component.hpp"
/*
 * Author: YonV
 * Puts one effector on a vehicle on HOLD, or takes it off (server, the one
 * arbiter). A hold is the crew's word that the system must not fire on its
 * own: HK HOLD stops the launchers, RF HOLD stops the emitter's automatic
 * burst - a manual BURST from the panel still works. Holds live on the
 * vehicle, public, so the HUD tile, every map panel and fnc_watch all read the
 * same answer.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Which - "hk" or "rf" <STRING>
 * 2: Hold <BOOL>
 *
 * Return Value: None
 *
 * Example:
 * [_tank, "rf", true] remoteExec ["jmfsb_aps_fnc_setHold", 2]
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]], ["_what", "", [""]], ["_hold", false, [false]]];
if (!isServer || {isNull _veh}) exitWith {};
if !(_what in ["hk", "rf"]) exitWith {};

private _var = [QGVAR(hkHold), QGVAR(rfHold)] select (_what isEqualTo "rf");
if ((_veh getVariable [_var, false]) isEqualTo _hold) exitWith {};

_veh setVariable [_var, _hold, true];
[_veh, -1, format ["%1 %2", ["HARD KILL", "RF EMITTER"] select (_what isEqualTo "rf"), ["AUTO", "HOLD"] select _hold]] remoteExec [QFUNC(report), [0, -2] select isDedicatedServer];
if (GVAR(debug)) then { INFO_3("%1: %2 hold %3",typeOf _veh,_what,_hold) };
