#include "script_component.hpp"
/*
 * Author: YonV
 * Holds ALiVE, or starts it. For a training mission: ALiVE's modules stand up
 * as normal, then pause, and nothing that starts on FUNC(whenReady) starts -
 * leaders, QRF, air defence, UAS - until an admin types #jmfsbalivestart.
 *
 * ALiVE's own pause (main fnc_pauseModule.sqf). A paused profile system
 * spawns nothing near players (sys_profile fnc_profileActivationTick.sqf); a
 * paused OPCOM gives no orders.
 *
 * Each module is paused as soon as it can take the call, in its own script:
 * the profile system once it reports startupComplete, OPCOM once its FSM is
 * up (its pause op waits for that itself, and must not be left waiting when
 * the start comes), the rest once their module logic has its class. A module
 * that is not placed is skipped.
 *
 * Set by the JMSB - Hold ALiVE module (jmfsb_modules). Started by the
 * #jmfsbalivestart chat command, admins only by the server's records.
 *
 * Arguments:
 * 0: Hold <BOOL> (optional, default true)
 *
 * Return Value: None
 *
 * Example:
 * [false] call jmfsb_adapter_alive_fnc_hold
 *
 * Public: Yes
 */

params [["_hold", true, [true]]];

if (!isServer) exitWith {};
if (isRemoteExecuted && {!([] call EFUNC(common,senderIsAdmin))}) exitWith {
    WARNING_1("hold: refused - machine %1 is not an admin",remoteExecutedOwner);
};

if (_hold isEqualTo (localNamespace getVariable [QGVAR(held), false])) exitWith {
    private _state = ["started", "held"] select _hold;
    INFO_1("hold: already %1",_state);
};

localNamespace setVariable [QGVAR(held), _hold];
missionNamespace setVariable [QGVAR(held), _hold, true];

if (!_hold) exitWith {
    INFO("ALiVE started by admin");
    [] spawn {HOLD_MODULES call ALiVE_fnc_unPauseModule};
    ["ALiVE", "Started", HINT_NOTIFY_COLOUR] remoteExecCall [QEFUNC(notify,notify), 0];
};

INFO("ALiVE held until #jmfsbalivestart");

{
    [_x] spawn {
        params ["_class"];

        private _mods = (entities "Module_F") select {toLower typeOf _x isEqualTo _class};
        if (_mods isEqualTo []) exitWith {};

        private _canPause = switch (_class) do {
            case "alive_sys_profile": {
                {
                    !isNil "ALIVE_profileSystem"
                    && {[ALIVE_profileSystem, "startupComplete", false] call ALiVE_fnc_hashGet}
                }
            };
            case "alive_mil_opcom": {
                {
                    (_mods findIf {
                        private _h = _x getVariable "handler";
                        isNil "_h"
                        || {!([_h, "startupComplete", false] call ALiVE_fnc_hashGet)}
                        || {
                            private _fsm = [_h, "OPCOM_FSM", -1] call ALiVE_fnc_hashGet;
                            _fsm < 0 || {isNil {_fsm getFSMVariable "_pause"}}
                        }
                    }) < 0
                }
            };
            default {
                {
                    (_mods findIf {
                        isNil {_x getVariable "class"} && {isNil {_x getVariable "handler"}}
                    }) < 0
                }
            };
        };

        waitUntil {
            sleep HOLD_POLL;
            !(localNamespace getVariable [QGVAR(held), false]) || {call _canPause}
        };
        if !(localNamespace getVariable [QGVAR(held), false]) exitWith {};

        [_class] call ALiVE_fnc_pauseModule;
        INFO_1("hold: %1 paused",_class);
    };
} forEach HOLD_MODULES;
