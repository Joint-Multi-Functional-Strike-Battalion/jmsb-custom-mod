#include "script_component.hpp"
/*
 * Author: JMSB
 * Finishes reading a virtual battery and puts it on the board - the part the
 * JMSB - Virtual Artillery module and the retired JMSB - Artillery Battery
 * module share. The caller has worked out what only it can: the stock, the
 * gun count, where the battery stands and its muzzle velocity and ranges.
 * Everything else is read here from the module's attributes, with the
 * Virtual Artillery defaults for a module that has none of them (the
 * Artillery Battery has only a callsign, an ammunition list and a cooldown).
 *
 * THE SIMPLEX FIRE MISSION. Besides the round types and ranges a battery
 * carries the knobs Simplex gives a mission maker: which sheaf types are
 * offered, the response time (a random wait between the order and the first
 * round), the cooldown added per round fired, the tops of the ROUNDS, DELAY,
 * INTERVAL and REPEAT steppers, and how far away another battery may be and
 * still join a coordinated mission.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Stock, [[name, roundsLeft, ammo class, kind], ...] <ARRAY>
 * 2: Gun count <NUMBER>
 * 3: Battery position, ATL <ARRAY>
 * 4: Muzzle velocity at full charge (m/s) <NUMBER>
 * 5: Minimum range (m) <NUMBER>
 * 6: Maximum range (m) <NUMBER>
 * 7: Platform text for the row <STRING>
 * 8: Default callsign <STRING>
 *
 * Return Value:
 * Asset id number, -1 when not registered <NUMBER>
 *
 * Example:
 * [_logic, _stock, 4, getPosATL _logic, 810, 2000, 24000, "VIRTUAL BATTERY", "THUNDER"] call jmfsb_support_fires_fnc_setupBattery
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_stock", [], [[]]],
    ["_guns", VA_DEF_GUNS, [0]],
    ["_origin", [], [[]]],
    ["_mv", VA_DEF_MV, [0]],
    ["_minRange", 0, [0]],
    ["_maxRange", VA_DEF_MAX_RANGE, [0]],
    ["_platform", "", [""]],
    ["_defCallsign", "THUNDER", [""]]
];

if (!isServer || {isNull _logic}) exitWith {-1};

private _callsign = _logic getVariable ["callsign", ""];

if (_stock isEqualTo []) exitWith {
    WARNING_1("Artillery '%1' carries no round type - no asset placed",_callsign);
    -1
};

// THE SHEAF TYPES OFFERED, by name, in the module's order; none valid offers
// them all rather than a battery that cannot be tasked.
private _sheafs = [];
{
    private _i = SHEAF_WORDS find (toUpper ([_x] call CBA_fnc_trim));
    if (_i > -1 && {!(_i in _sheafs)}) then {_sheafs pushBack _i};
} forEach ((_logic getVariable ["sheafTypes", VA_DEF_SHEAFS]) splitString ",");
if (_sheafs isEqualTo []) then {
    WARNING_1("Artillery '%1': no valid sheaf type named - all four offered",_callsign);
    _sheafs = [SHEAF_CONVERGED, SHEAF_PARALLEL, SHEAF_BOX, SHEAF_CREEPING];
};

private _respMin = 0 max (_logic getVariable ["responseMin", 0]);

_logic setVariable [QGVAR(stock), _stock, true];
_logic setVariable [QGVAR(gunCount), 1 max round _guns, true];
_logic setVariable [QGVAR(origin), _origin, true];
_logic setVariable [QGVAR(platform), _platform, true];
_logic setVariable [QGVAR(muzzleVelocity), 50 max _mv, true];
_logic setVariable [QGVAR(minRange), 0 max _minRange, true];
_logic setVariable [QGVAR(maxRange), (0 max _minRange) max _maxRange, true];
_logic setVariable [QGVAR(dispersion), 0 max (_logic getVariable ["dispersion", VA_DEF_DISPERSION]), true];
_logic setVariable [QGVAR(highAngle), (_logic getVariable ["trajectory", 1]) isEqualTo 1, true];
_logic setVariable [QGVAR(reload), 1 max (_logic getVariable ["reload", VA_DEF_RELOAD]), true];
_logic setVariable [QGVAR(cooldown), 0 max (_logic getVariable ["cooldown", VA_DEF_COOLDOWN]), true];
_logic setVariable [QGVAR(roundCooldown), 0 max (_logic getVariable ["roundCooldown", VA_DEF_ROUND_CD]), true];
_logic setVariable [QGVAR(response), [_respMin, _respMin max (_logic getVariable ["responseMax", 0])], true];
_logic setVariable [QGVAR(sheafs), _sheafs, true];
_logic setVariable [QGVAR(maxRounds), 1 max round (_logic getVariable ["maxRounds", VA_DEF_MAX_ROUNDS]), true];
_logic setVariable [QGVAR(maxDelay), 0 max round (_logic getVariable ["maxDelay", VA_DEF_MAX_DELAY]), true];
_logic setVariable [QGVAR(maxInterval), 0 max round (_logic getVariable ["maxInterval", VA_DEF_MAX_INTERVAL]), true];
_logic setVariable [QGVAR(maxRepeat), 0 max round (_logic getVariable ["maxRepeat", VA_DEF_MAX_REPEAT]), true];
_logic setVariable [QGVAR(coordination), 0 max (_logic getVariable ["coordination", VA_DEF_COORDINATION]), true];

[_logic, TYPE_ARTY, _callsign, _defCallsign] call FUNC(register)
