#include "script_component.hpp"
/*
 * Author: YonV
 * The "reach" code of provider "logi" (support core README, 2026-11-01):
 * whether this asset can deliver to one map point, how soon and with what -
 * its row of the board's reach card. Asked once per target click on the
 * viewer's machine, so it reads only what the server published on the
 * module.
 *
 * THE ETA is FUNC(eta): the leg in from the module, where its aircraft is
 * made when tasked (user, 2026-11-02). The effect is what it can bring, and
 * the replacements it has for aircraft lost:
 *
 *   "AIRDROP / SLING - 4 PER ORDER - 6 ITEMS - 2 SPARE AIRFRAMES"
 *
 * Tasks are its methods (FUNC(tasks)); nothing about the point rules one
 * out - the cart does that, on the type screen.
 *
 * CANNOT: "TASKED", "COOLDOWN n S", "REPLACING", "EXPENDED", "UNABLE - NO
 * AIRFRAME" (its Respawns used, 2026-11-02).
 *
 * Arguments:
 * 0: Asset id, "logi:<n>" <STRING>
 * 1: The point, [x, y, z] ATL <ARRAY>
 *
 * Return Value:
 * 0: Can service the point now <BOOL>
 * 1: ETA in seconds, -1 unknown <NUMBER>
 * 2: Why not, "" when it can <STRING>
 * 3: Effect, one line <STRING>
 * 4: Task tokens valid at the point <ARRAY of STRINGs>
 *
 * Example:
 * ["logi:0", [1000, 2000, 0]] call jmfsb_support_logistics_fnc_reach
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_pos", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, ETA_UNKNOWN, "GONE", "", []]};

private _tasks = ([_assetId, []] call FUNC(tasks)) apply {_x select 0};
private _left = _logic getVariable [QGVAR(left), -1];
private _words = [
    _tasks joinString " / ",
    format ["%1 PER ORDER", _logic getVariable [QGVAR(capacity), DEF_CAPACITY]],
    format ["%1 ITEMS", count (_logic getVariable [QGVAR(catalog), []])],
    ["", format [SPARE_WORDS select ((count SPARE_WORDS - 1) - (_left min (count SPARE_WORDS - 1))), _left]] select (_left >= 0)
];
private _effect = (_words select {_x isNotEqualTo ""}) joinString REACH_SEP;

([_logic] call FUNC(available)) params ["_ok", "_status"];
if (!_ok) exitWith {
    private _why = switch (_status) do {
        case STATUS_EXPENDED: {"EXPENDED"};
        case STATUS_GONE: {WHY_NO_AIRFRAME};
        case STATUS_REPLACING: {"REPLACING"};
        case STATUS_COOLDOWN: {format ["COOLDOWN %1 S", ceil ((_logic getVariable [QGVAR(readyAt), 0]) - CBA_missionTime)]};
        default {"TASKED"};
    };
    [false, ETA_UNKNOWN, _why, _effect, []]
};
if (count _pos < 2) exitWith {[false, ETA_UNKNOWN, "NO TARGET POINT", _effect, []]};
if (_tasks isEqualTo []) exitWith {[false, ETA_UNKNOWN, "NO TASK FITS", _effect, []]};

[true, [_logic, _pos] call FUNC(eta), "", _effect, _tasks]
