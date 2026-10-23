#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts one placed air module on the board: works out the aircraft, the side
 * and the base, and gives the module its asset id.
 *
 * WHAT THE FOUR MODULES SHARE, and the only place they share it. Each module
 * function reads its own attributes onto the logic first and then calls this,
 * so a module that is refused here (no such class, wrong kind of aircraft)
 * never reaches TAC//SUPPORT at all - no module, no asset, and a bad module
 * is no asset either, loudly in the RPT.
 *
 * THE SIDE IS THE PLAYERS' (D59), read from the slots the way the CAS drone
 * module reads it. A module never asks.
 *
 * THE BASE IS THE MODULE, or the aircraft synced to it: a synced aircraft
 * flies from where it stands and is parked back there, a class is created at
 * the module and goes home to it.
 *
 * A SYNCED AIRCRAFT'S CREW IS PHOTOGRAPHED HERE - class, seat and loadout of
 * every crew seat - so a respawn (FUNC(respawn)) and a return to base
 * (FUNC(rearm)) put the same men back in the same seats, the way Simplex
 * restores its crews.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Asset type - KIND_CAS, KIND_TRANSPORT, ... <STRING>
 * 2: Callsign when the module gives none <STRING>
 * 3: What the aircraft must be a kind of - "Air", "Helicopter" <STRING>
 * 4: May a synced aircraft be flown instead of a class <BOOL>
 *
 * Return Value:
 * On the board <BOOL>
 *
 * Example:
 * [_logic, "cas", "HOG", "Air", true] call jmfsb_support_air_fnc_register
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_kind", "", [""]],
    ["_fallbackCallsign", "", [""]],
    ["_needs", "Air", [""]],
    ["_allowSynced", false, [false]]
];

if (isNull _logic || {_logic in GVAR(entities)}) exitWith {false};

private _side = (call EFUNC(common,playerSides)) param [0, west];

// EDEN WRITES THE PLAIN NAME. The attribute expression sets 'aircraftClass'
// on the logic; the prefixed copies below are what the runtime reads.
private _synced = objNull;
if (_allowSynced) then {
    private _air = (synchronizedObjects _logic) select {_x isKindOf "Air"};
    _synced = _air param [0, objNull];
};

private _cls = if (isNull _synced) then {_logic getVariable ["aircraftClass", ""]} else {typeOf _synced};
if (_cls isEqualTo "") then {_cls = [_kind, _side] call FUNC(defaultClass)};

if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith {
    WARNING_2("%1 module names aircraft '%2', which is not a class in this mission - no asset placed",_kind,_cls);
    false
};
if !(_cls isKindOf _needs) exitWith {
    WARNING_3("%1 module aircraft '%2' is not a %3 - no asset placed",_kind,_cls,_needs);
    false
};

private _callsign = _logic getVariable ["callsign", ""];
if (_callsign isEqualTo "") then {_callsign = _fallbackCallsign};

private _home = if (isNull _synced) then {getPosATL _logic} else {getPosATL _synced};
private _homeDir = if (isNull _synced) then {getDir _logic} else {getDir _synced};

_logic setVariable [QGVAR(kind), _kind, true];
_logic setVariable [QGVAR(side), _side, true];
_logic setVariable [QGVAR(cls), _cls, true];
_logic setVariable [QGVAR(synced), _synced, true];
// Kept apart from the object: a wreck that is cleaned up reads objNull, and
// an asset whose aircraft was deleted must not read as a class asset again.
_logic setVariable [QGVAR(hadSynced), !isNull _synced, true];
_logic setVariable [QGVAR(callsign), toUpper _callsign, true];
_logic setVariable [QGVAR(home), _home, true];
_logic setVariable [QGVAR(homeDir), _homeDir, true];
// ASL as well: a stand on a deck or a roof is not where ATL puts it.
_logic setVariable [QGVAR(homeASL), [AGLToASL _home, getPosASL _synced] select (!isNull _synced)];
_logic setVariable [QGVAR(spawnDelay), 0 max (_logic getVariable ["spawnDelay", 60]), true];
_logic setVariable [QGVAR(cooldown), 0 max (_logic getVariable ["cooldown", 300]), true];
// Anything below zero is "never"; the attribute's own -1 is the documented way.
private _respawn = _logic getVariable ["respawnDelay", RESPAWN_NEVER];
_logic setVariable [QGVAR(respawnDelay), [_respawn, RESPAWN_NEVER] select (_respawn < 0), true];
private _trigger = _logic getVariable ["cooldownTrigger", COOLDOWN_AT_END];
// COOLDOWN_AT_END is 0 and COOLDOWN_AT_START 1, so the flag is the number.
_logic setVariable [QGVAR(cooldownTrigger), parseNumber (_trigger isEqualTo COOLDOWN_AT_START), true];
_logic setVariable [QGVAR(respawnAt), 0, true];
_logic setVariable [QGVAR(dead), false, true];
_logic setVariable [QGVAR(plan), [], true];

// Running state, public: the support page reads it on the client.
_logic setVariable [QGVAR(status), STATUS_IDLE, true];
_logic setVariable [QGVAR(vehicle), _synced, true];
_logic setVariable [QGVAR(readyAt), 0, true];
_logic setVariable [QGVAR(lost), 0, true];
_logic setVariable [QGVAR(abort), false, true];

// A SYNCED AIRCRAFT IS THE ASSET, so losing it is losing the asset - until
// its replacement is on the stand. Wired here once rather than at each
// launch, because it can be shot up on the pad before anyone ever tasks it.
if (!isNull _synced) then {
    // Crew seats only: whoever the mission maker sat in the back is a
    // passenger, not crew.
    private _crew = (fullCrew [_synced, "", false]) select {(_x select 1) in ["driver", "commander", "gunner", "turret"]};
    _logic setVariable [QGVAR(crew), _crew apply {
        _x params ["_unit", "_role", "", "_turret"];
        [typeOf _unit, _role, _turret, getUnitLoadout _unit]
    }];
    [_logic, _synced] call FUNC(adopt);
};

// THE ID IS THE INDEX, and the list is published: TAC//SUPPORT is drawn on
// the client and resolves "air:<n>" there.
GVAR(entities) pushBack _logic;
_logic setVariable [QGVAR(id), count GVAR(entities) - 1, true];
publicVariable QGVAR(entities);

INFO_4("%1 asset '%2' on the board for %3 flying %4",_kind,toUpper _callsign,_side,_cls);

true
