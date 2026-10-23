#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: what kind of signal an emitter looks like to ES (DESIGN_EW
 * "Identify"), by band, intent and duty - never by the decoy mark, which is
 * exactly what a decoy hides:
 *
 *   JAM / SPOOF  a jammer or spoofer (its energy gives it away)
 *   VIDEO        a drone link (VIDEO band only)
 *   DATA         a set on the data net only
 *   DECOY?       a set that has carried no traffic for DECOY_QUIET_S since it
 *                was first heard - a real set that keeps quiet reads the same
 *   COMMS        anything else
 *
 * Arguments:
 * 0: Emitter, as FUNC(collect) builds it <HASHMAP>
 *
 * Return Value:
 * Class <STRING>
 *
 * Example:
 * [_emitter] call jmfsb_ew_fnc_classify
 *
 * Public: No
 */

params [["_e", createHashMap, [createHashMap]]];

private _intent = _e get "intent";
if (_intent isEqualTo INTENT_JAM) exitWith {CLASS_JAM};
if (_intent isEqualTo INTENT_SPOOF) exitWith {CLASS_SPOOF};
if ((_e get "bands") isEqualTo ["VIDEO"]) exitWith {CLASS_VIDEO};
if ((_e get "nets") isEqualTo [NET_DATA]) exitWith {CLASS_DATA};

if ((_e get "source") isEqualTo SRC_RF) then {
    private _id = _e get "id";
    private _now = CBA_missionTime;
    private _quietSince = GVAR(lastTx) getOrDefault [_id, GVAR(firstSeen) getOrDefault [_id, _now]];
    if ((_now - _quietSince) >= DECOY_QUIET_S) exitWith {CLASS_DECOY};
    CLASS_COMMS
} else {
    CLASS_COMMS
}
