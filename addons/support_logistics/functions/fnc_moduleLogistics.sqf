#include "script_component.hpp"
/*
 * Author: YonV
 * Reads one JMSB - Logistics module, builds its catalog and puts it on
 * TAC//SUPPORT as asset "logi:<n>".
 *
 * NO MODULE, NO ASSET - AND A BAD MODULE IS NO ASSET EITHER, loudly in the
 * RPT: an aircraft class that is not one, or not an aircraft, or a catalog
 * with nothing in it.
 *
 * THE METHODS ARE WHAT THE AIRCRAFT CAN FLY. SLING needs a helicopter with a
 * cargo hook (config slingLoadMaxCargoMass); a module that ticks only SLING
 * for anything else is flown as an AIRDROP, once, with a warning - the old
 * Logistics Drop's rule, kept for the missions that placed it.
 *
 * THE CATALOG (published on the logic, QGVAR(catalog)) is, in this order:
 * every item of every synced JMSB - Logistics Catalog (FUNC(catalogRead)),
 * then one supply crate per PAC load named in PAC Arsenal Lists (';' between
 * loads; FUNC(fillCrate) packs it at launch). With neither, one crate that
 * keeps its class's own contents. Names are made unique, so the ITEM stepper
 * never shows two the same.
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
 * [_logic, [], true] call jmfsb_support_logistics_fnc_moduleLogistics
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic} || {!isServer}) exitWith {};
if (_logic in GVAR(entities)) exitWith {};

// THE SIDE IS READ ONCE, FROM THE SLOTS (D59). A dedicated server that
// starts the mission empty has none to read yet, and a guess would fix the
// asset on the wrong side for good - so it waits for the first player.
if ((call EFUNC(common,playerSides)) isEqualTo []) exitWith {
    INFO_1("%1 waits for a player side before it goes on the board",_logic);
    [{(call EFUNC(common,playerSides)) isNotEqualTo []}, FUNC(moduleLogistics), _this] call CBA_fnc_waitUntilAndExecute;
};

private _side = (call EFUNC(common,playerSides)) param [0, west];

// ------------------------------------------------------------- aircraft --
private _cls = _logic getVariable ["aircraftClass", ""];
if (_cls isEqualTo "") then {_cls = DEF_AIRCRAFT select (([west, east, independent] find _side) max 0)};
if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith {
    WARNING_1("logistics module names aircraft '%1', which is not a class in this mission - no asset placed",_cls);
};
if !(_cls isKindOf "Air") exitWith {
    WARNING_1("logistics module aircraft '%1' is not an aircraft - no asset placed",_cls);
};

private _hookMass = [0, getNumber (configFile >> "CfgVehicles" >> _cls >> "slingLoadMaxCargoMass")] select (_cls isKindOf "Helicopter");
private _methods = [];
if ([_logic getVariable ["allowAirdrop", true]] call EFUNC(support_air,bool)) then {_methods pushBack TASK_AIRDROP};
if ([_logic getVariable ["allowSling", true]] call EFUNC(support_air,bool)) then {
    if (_hookMass > 0) then {
        _methods pushBack TASK_SLING;
    } else {
        WARNING_1("logistics: '%1' has no cargo hook - SLING LOAD not offered",_cls);
    };
};
if (_methods isEqualTo []) then {
    WARNING_1("logistics: '%1' can fly none of the methods ticked - it airdrops",_cls);
    _methods = [TASK_AIRDROP];
};

// ----------------------------------------------------------------- crate --
private _crate = _logic getVariable ["crateClass", DEF_CRATE];
if !(isClass (configFile >> "CfgVehicles" >> _crate)) then {
    WARNING_2("logistics module names crate '%1', which is not a class - %2 instead",_crate,DEF_CRATE);
    _crate = DEF_CRATE;
};

// --------------------------------------------------------------- catalog --
// A copy: one catalog module may feed several logistics modules, and the
// names below are made unique per module.
private _catalog = [];
{
    _catalog append +([_x] call FUNC(catalogRead));
} forEach ((synchronizedObjects _logic) select {typeOf _x isEqualTo QGVAR(moduleCatalog)});

// THE PAC CRATES. Their mass is read off one made for the purpose, here and
// only here, so the sling check never has to guess.
private _loads = ((_logic getVariable ["arsenalLists", DEF_LISTS]) splitString ";") apply {trim _x} select {_x isNotEqualTo ""};
if (_loads isEqualTo [] && {_catalog isEqualTo []}) then {_loads = [""]};
if (_loads isNotEqualTo []) then {
    private _probe = _crate createVehicleLocal [0, 0, 0];
    private _mass = [-1, getMass _probe] select (!isNull _probe);
    deleteVehicle _probe;
    private _hook = (getArray (configFile >> "CfgVehicles" >> _crate >> "slingLoadCargoMemoryPoints")) isNotEqualTo [];
    private _box = toUpper getText (configFile >> "CfgVehicles" >> _crate >> "displayName");
    {
        private _name = [format ["CRATE - %1", toUpper _x], _box] select (_x isEqualTo "");
        _catalog pushBack [_name, ITEM_CRATE, _crate, [], [], _mass, _hook, _x];
    } forEach _loads;
};

// One name, one item.
private _seen = createHashMap;
{
    private _name = _x select ITEM_NAME;
    private _n = (_seen getOrDefault [_name, 0]) + 1;
    _seen set [_name, _n];
    if (_n > 1) then {_x set [ITEM_NAME, format ["%1 (%2)", _name, _n]]};
} forEach _catalog;

// ---------------------------------------------------------------- values --
private _callsign = _logic getVariable ["callsign", ""];
if (_callsign isEqualTo "") then {_callsign = DEF_CALLSIGN};
// RESPAWNS (user, 2026-11-02: "make sure there is a respawn count for each
// support, default no respawns"; the same day, virtual until tasked): the
// replacements for aircraft lost. A delivery is made over the module when
// tasked and removed there when home - that uses none (FUNC(lost)). -1
// unlimited.
private _respawns = round (_logic getVariable ["respawns", DEF_RESPAWNS]);
private _signal = (round (_logic getVariable ["signal", 0])) max 0 min (count MARK_CLASSES - 1 - MARK_MODULE_OFFSET);
private _open = _logic getVariable ["openHeight", DEF_OPEN_HEIGHT];
private _respawn = _logic getVariable ["respawnDelay", DEF_RESPAWN];
private _trigger = _logic getVariable ["cooldownTrigger", COOLDOWN_AT_END];

_logic setVariable [QGVAR(side), _side, true];
_logic setVariable [QGVAR(cls), _cls, true];
_logic setVariable [QGVAR(callsign), toUpper _callsign, true];
_logic setVariable [QGVAR(home), getPosATL _logic, true];
_logic setVariable [QGVAR(methods), _methods, true];
_logic setVariable [QGVAR(hookMass), _hookMass, true];
_logic setVariable [QGVAR(catalog), _catalog, true];
_logic setVariable [QGVAR(capacity), 1 max round (_logic getVariable ["capacity", DEF_CAPACITY]), true];
_logic setVariable [QGVAR(slingEach), (_logic getVariable ["fulfillment", FULFIL_EACH]) isEqualTo FULFIL_EACH, true];
_logic setVariable [QGVAR(dropHeight), DROP_HEIGHT_MIN max (_logic getVariable ["dropHeight", DEF_DROP_HEIGHT]), true];
_logic setVariable [QGVAR(openHeight), [OPEN_HEIGHT_MIN max _open, -1] select (_open < 0), true];
_logic setVariable [QGVAR(unloadHeight), UNLOAD_HEIGHT_MIN max (_logic getVariable ["unloadHeight", DEF_UNLOAD_HEIGHT]), true];
_logic setVariable [QGVAR(cooldown), 0 max (_logic getVariable ["cooldown", DEF_COOLDOWN]), true];
_logic setVariable [QGVAR(itemCooldown), 0 max (_logic getVariable ["itemCooldown", DEF_ITEM_COOLDOWN]), true];
// The replacement's wait. Its old -1 "never" is Respawns 0 now (user,
// 2026-11-02), so a mission that set it waits no time.
_logic setVariable [QGVAR(respawnDelay), 0 max _respawn, true];
// COOLDOWN_AT_END is 0 and COOLDOWN_AT_START 1, so the flag is the number.
_logic setVariable [QGVAR(cooldownTrigger), parseNumber (_trigger isEqualTo COOLDOWN_AT_START), true];
_logic setVariable [QGVAR(left), [_respawns, RESPAWNS_UNLIMITED] select (_respawns < 0), true];
_logic setVariable [QGVAR(stock), _respawns max 0, true];
_logic setVariable [QGVAR(noAirframe), false];
_logic setVariable [QGVAR(crateClass), _crate, true];
_logic setVariable [QGVAR(magCount), 0 max round (_logic getVariable ["magCount", DEF_MAG_COUNT]), true];
_logic setVariable [QGVAR(itemCount), 0 max round (_logic getVariable ["itemCount", DEF_ITEM_COUNT]), true];
_logic setVariable [QGVAR(signalClass), MARK_CLASSES select (_signal + MARK_MODULE_OFFSET), true];

// Running state, public: the support page reads it on the client.
_logic setVariable [QGVAR(status), STATUS_IDLE, true];
_logic setVariable [QGVAR(vehicle), objNull, true];
_logic setVariable [QGVAR(plan), [], true];
_logic setVariable [QGVAR(readyAt), 0, true];
_logic setVariable [QGVAR(respawnAt), 0, true];
_logic setVariable [QGVAR(lost), 0, true];
_logic setVariable [QGVAR(gone), false, true];
_logic setVariable [QGVAR(abort), false, true];

// THE ID IS THE INDEX, and the list is published: TAC//SUPPORT is drawn on
// the client and resolves "logi:<n>" there.
GVAR(entities) pushBack _logic;
_logic setVariable [QGVAR(id), count GVAR(entities) - 1, true];
publicVariable QGVAR(entities);

INFO_5("logistics asset '%1' on the board for %2 flying %3 - %4, %5 items",toUpper _callsign,_side,_cls,_methods,count _catalog);
