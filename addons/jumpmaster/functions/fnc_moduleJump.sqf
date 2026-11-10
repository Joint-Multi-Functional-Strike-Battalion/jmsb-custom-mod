#include "script_component.hpp"
/*
 * Author: YonV
 * Server: reads one JMSB - Jump Aircraft module and puts the aircraft it
 * describes in TAC//MSG (user, 2026-11-02: "Jump aircraft module" - class,
 * call sign, altitudes, side; several jump aircraft per side). Many modules
 * are many aircraft, each its own asset "jump:<n>"; a side with a module no
 * longer has the settings' own jump aircraft (FUNC(asset)).
 *
 * THE SIDE IS NEVER TYPED (D59): the side of the units synced to the module,
 * else the players' side from the slots, as support_air's modules read it. A
 * dedicated server that starts the mission empty has no slots to read yet, so
 * a module synced to nobody waits for the first player.
 *
 * VIRTUAL UNTIL TASKED (user, 2026-11-02: "all support aircraft needs to be
 * virtual till tasked, then they spawn in at alt over the support module
 * location"): nothing is made here. A JUMP REQUEST accepted makes its aircraft
 * over the module (FUNC(airUp)); after the task it flies home and is removed
 * (FUNC(airHome)); a loss uses one of the module's Respawns (FUNC(airLost)).
 *
 * A BAD MODULE IS NO ASSET, loudly in the RPT: a class that is not in the
 * mission or not an aircraft. Placed by Zeus it flies the attributes'
 * defaults, as the other support modules do.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, [], true] call jmfsb_jumpmaster_fnc_moduleJump
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic} || {!isServer}) exitWith {};
if (_logic in GVAR(entities)) exitWith {};

private _synced = ((synchronizedObjects _logic) + _units) apply {side group _x} select {_x in JUMP_SIDES};
if (_synced isEqualTo [] && {(call EFUNC(common,playerSides)) isEqualTo []}) exitWith {
    INFO_1("%1 waits for a player side before it goes in TAC//MSG",_logic);
    [{(call EFUNC(common,playerSides)) isNotEqualTo []}, FUNC(moduleJump), _this] call CBA_fnc_waitUntilAndExecute;
};
private _side = _synced param [0, (call EFUNC(common,playerSides)) param [0, west]];

// EDEN WRITES THE PLAIN NAMES (the attributes' expressions); the prefixed
// copies below are what the asset reads, public for the client's row.
private _cls = trim (_logic getVariable ["aircraftClass", ""]);
if (_cls isEqualTo "") then {_cls = [_side] call FUNC(aircraftClass)};
if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith {
    WARNING_1("Jump Aircraft module names '%1', which is not a class in this mission - no asset placed",_cls);
};
if !(_cls isKindOf "Air") exitWith {
    WARNING_1("Jump Aircraft module class '%1' is not an aircraft - no asset placed",_cls);
};

private _callsign = toUpper trim (_logic getVariable ["callsign", ""]);
if (_callsign isEqualTo "") then {_callsign = JUMP_CALLSIGN};

private _freefall = {
    params ["_name"];
    (_logic getVariable [_name, ALT_FREEFALL_DEFAULT]) max ALT_FREEFALL_MIN min ALT_FREEFALL_MAX
};
private _alts = [
    ["haloAltitude"] call _freefall,
    ["hahoAltitude"] call _freefall,
    (_logic getVariable ["staticAltitude", ALT_STATIC_DEFAULT]) max ALT_STATIC_MIN min ALT_STATIC_MAX
];
_logic setVariable [QGVAR(side), _side, true];
_logic setVariable [QGVAR(cls), _cls, true];
_logic setVariable [QGVAR(callsign), _callsign, true];
_logic setVariable [QGVAR(alts), _alts apply {round _x}, true];
_logic setVariable [QGVAR(passes), (round (_logic getVariable ["passes", MODULE_PASSES])) max PASSES_MIN min PASSES_MAX, true];
_logic setVariable [QGVAR(exit), EXITS param [round (_logic getVariable ["exit", 0]), EXIT_AUTO], true];
_logic setVariable [QGVAR(bay), BAYS param [round (_logic getVariable ["bay", 0]), BAY_SEATS], true];
_logic setVariable [QGVAR(cooldown), 0 max (_logic getVariable ["cooldown", MODULE_COOLDOWN]), true];
// THE RESPAWN COUNT (user, 2026-11-02: "make sure there is a respawn count for
// each support, default no respawns"): replacements left, and how long each
// takes after a loss (FUNC(airLost)).
_logic setVariable [QGVAR(respawns), 0 max round (_logic getVariable ["respawns", MODULE_RESPAWNS]), true];
_logic setVariable [QGVAR(respawnDelay), 0 max (_logic getVariable ["respawnDelay", MODULE_RESPAWN_DELAY]), true];
// Running state, public: the row is drawn on the client.
_logic setVariable [QGVAR(busy), false, true];
_logic setVariable [QGVAR(readyAt), 0, true];
_logic setVariable [QGVAR(run), [], true];
_logic setVariable [QGVAR(veh), objNull, true];
_logic setVariable [QGVAR(airPhase), AIR_VIRTUAL, true];
_logic setVariable [QGVAR(replaceAt), 0, true];

GVAR(entities) pushBack _logic;
_logic setVariable [QGVAR(id), count GVAR(entities) - 1, true];
publicVariable QGVAR(entities);

INFO_3("jump aircraft '%1' in TAC//MSG for %2 flying %3 - virtual until tasked",_callsign,_side,_cls);
