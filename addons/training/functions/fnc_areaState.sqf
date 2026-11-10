#include "script_component.hpp"
/*
 * Author: YonV
 * A training area's live state and after-action numbers (user, 2026-11-07),
 * kept on the server and published per area, so every trainer's app reads the
 * same: spawned, killed, when the first shot came, when the last enemy fell,
 * and how many trainees went down inside it meanwhile.
 *
 *     [status, spawned, killed, startedAt, firstShotAt, clearedAt, casualties,
 *      faction, density, patrol, by]
 *
 * status is "idle", "live", "cleared" (every enemy dead) or "stopped" (the
 * trainer cleared it). Times are serverTime, -1 for not yet.
 *
 * Arguments:
 * 0: Area marker <STRING>
 * 1: What happened - "spawned", "shot", "killed", "casualty", "stopped", "" to read <STRING>
 * 2: For "spawned": [count, faction name, density name, patrol m, by] <ARRAY> (optional)
 *
 * Return Value:
 * The state <ARRAY>
 *
 * Example:
 * ["ta_cqb_house1"] call jmfsb_training_fnc_areaState
 *
 * Public: No
 */

params [["_marker", "", [""]], ["_what", "", [""]], ["_args", [], [[]]]];

private _key = format ["%1_%2", QGVAR(state), _marker];
private _state = +(missionNamespace getVariable [_key, ["idle", 0, 0, -1, -1, -1, 0, "", "", 0, ""]]);
if (_what isEqualTo "" || !isServer || _marker isEqualTo "") exitWith {_state};

private _live = (_state # 0) isEqualTo "live";
switch (_what) do {
    case "spawned": {
        _args params [["_count", 0], ["_faction", ""], ["_density", ""], ["_patrol", 0], ["_by", ""]];
        _state = ["live", _count, 0, serverTime, -1, -1, 0, _faction, _density, _patrol, _by];
    };
    case "shot": {
        if (_live && {(_state # 4) < 0}) then {_state set [4, serverTime]};
    };
    case "killed": {
        if (!_live) exitWith {};
        _state set [2, (_state # 2) + 1];
        if ((_state # 2) >= (_state # 1)) then {
            _state set [0, "cleared"];
            _state set [5, serverTime];
        };
    };
    case "casualty": {
        if (_live) then {_state set [6, (_state # 6) + 1]};
    };
    case "stopped": {
        if (_live) then {_state set [0, "stopped"]; _state set [5, serverTime]};
    };
};

missionNamespace setVariable [_key, _state, true];
_state
