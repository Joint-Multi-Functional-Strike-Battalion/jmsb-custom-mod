#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: the server's answer to an echo test (FUNC(srvEchoToken)) - the voice
 * server's address and his token, and the extension joins; or why not, and
 * the test ends. Taken only from the server, and only while joining.
 *
 * Arguments:
 * 0: Signed <BOOL>
 * 1: Voice server address, or why not <STRING>
 * 2: Token <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [true, "ws://host:7880", _token] call jmfsb_adapter_livekit_fnc_echoAnswer
 *
 * Public: No
 */

params [["_ok", false, [false]], ["_url", "", [""]], ["_token", "", [""]]];

if (isMultiplayer && {isRemoteExecuted} && {remoteExecutedOwner isNotEqualTo 2}) exitWith {};
if (GVAR(echo) isNotEqualTo ECHO_JOINING) exitWith {};
if (!_ok) exitWith {[false, format ["The server cannot sign you in: %1.", _url]] call FUNC(echo)};

(["connect", [_url, _token]] call FUNC(ext)) params ["_result", "_ran"];
if (!_ran) then {[false, format ["The voice extension cannot connect: %1.", _result]] call FUNC(echo)};
