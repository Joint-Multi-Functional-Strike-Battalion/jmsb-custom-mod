#include "script_component.hpp"
/*
 * Author: YonV
 * The TRAINING tile: how many training areas are live and how many patients
 * are on the stretchers. Only for a man FUNC(access) lets in - nobody else gets
 * a tile, so nobody else gets a way into the app.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Tile entries, [] or one [appId, kicker, qualifier, value, detail, state] <ARRAY>
 *
 * Example:
 * [] call jmfsb_training_fnc_tile
 *
 * Public: No
 */

if !([player] call FUNC(access)) exitWith {[]};

private _live = {(([_x # 0] call FUNC(areaState)) # 0) isEqualTo "live"} count ([] call FUNC(areas));
private _patients = {!isNull ((_x # 1) getVariable [QGVAR(patient), objNull])} count ([] call FUNC(stretchers));

[[
    APP_ID,
    "TRAINING",
    "LIVE",
    str _live,
    format ["%1 AREA%2 LIVE - %3 PATIENT%4", _live, ["S", ""] select (_live isEqualTo 1), _patients, ["S", ""] select (_patients isEqualTo 1)],
    ["rest", "warn"] select (_live > 0)
]]
