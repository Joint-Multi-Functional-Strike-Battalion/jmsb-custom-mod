#include "script_component.hpp"
/*
 * Author: YonV
 * Server: nobody answered the drone's prompt for 5 min (D9, user 2026-11-01;
 * the support core's prompt calls this, DESIGN_SUPPORT_MESSAGING 5.4 and step
 * 5) - AWAITING CLEARED HOT, REQUEST BDA, RE-ATTACK?, FURTHER TASKING?. It
 * leaves (off the map, as a recall) and the thread closes NO RESPONSE - RTB.
 * Only for the thread it is flying now.
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["cas:0", "T0042"] call jmfsb_cas_fnc_threadTimeout
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_threadId", "", [""]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("threadTimeout: refused - remote call from machine %1",remoteExecutedOwner);
};

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
if (isNull _logic) exitWith {};
if ((_logic getVariable [QGVAR(thread), ""]) isNotEqualTo _threadId) exitWith {};
if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) in STATUSES_NO_RUN) exitWith {};

INFO_2("%1: no answer in thread %2 - leaving",_logic getVariable [ARR_2(QGVAR(callsign),"CAS")],_threadId);
(_logic getVariable [QGVAR(run), createHashMap]) set ["said", SAID_NO_RESPONSE];
_logic setVariable [QGVAR(abort), true, true];
