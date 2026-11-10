#include "script_component.hpp"
/*
 * Author: YonV
 * A vehicle range's state, published to every machine so the TAC//TRAINING
 * app reads it anywhere. With no event it only reads.
 *
 *     ["vr_1200_3400"]                                read
 *     ["vr_1200_3400", "spawned", [vehicles, by, direction label, speed]]
 *     ["vr_1200_3400", "stopped"]
 *
 * State: [status ("idle" | "live" | "stopped"), vehicles, serverTime spawned,
 * set by, direction label, speed km/h, serverTime it despawns (-1 never)].
 * Destroyed is worked out by the reader from the vehicles.
 *
 * Arguments:
 * 0: Range key <STRING>
 * 1: Event <STRING> (optional, default "")
 * 2: Event arguments <ARRAY> (optional, default [])
 *
 * Return Value:
 * State <ARRAY>
 *
 * Example:
 * ["vr_1200_3400"] call jmfsb_training_fnc_vehState
 *
 * Public: No
 */

params [["_key", "", [""]], ["_what", "", [""]], ["_args", [], [[]]]];

private _var = format ["%1_%2", QGVAR(rangeState), _key];
private _state = +(missionNamespace getVariable [_var, ["idle", [], -1, "", "", 0, -1]]);
if (_what isEqualTo "" || !isServer || _key isEqualTo "") exitWith {_state};

switch (_what) do {
    case "spawned": {
        _args params [["_vehicles", []], ["_by", ""], ["_dirLabel", ""], ["_speed", 0], ["_despawnAt", -1]];
        _state = ["live", _vehicles, serverTime, _by, _dirLabel, _speed, _despawnAt];
    };
    case "stopped": {
        _state set [0, "stopped"];
        _state set [1, []];
        _state set [6, -1];
    };
};

missionNamespace setVariable [_var, _state, true];
_state
