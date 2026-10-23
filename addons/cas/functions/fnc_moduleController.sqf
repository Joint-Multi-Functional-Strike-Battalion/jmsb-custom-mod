#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads one CAS module and puts the asset it describes on the board.
 *
 * MANY MODULES, AND THAT IS DELIBERATE. The enemy-drone module refuses a
 * second placement because a second would arm one system twice. This is the
 * opposite case: a module IS an airframe, so two modules are two aircraft and
 * a mission that wants a flight of three places three. Nothing here is
 * global state - every value read below lands on the logic it came from.
 *
 * WHOSE IT IS COMES FROM JMSB - Core, NOT FROM AN ATTRIBUTE (D59). Adding a
 * side field here would be a second place allegiance is typed, and the two
 * would disagree the first time a mission changed one of them.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};

// Placement order is the id order, and a module already registered is not
// registered twice - isGlobal 2 means this can run again on a JIP pass.
if (_logic in GVAR(entities)) exitWith {};

// EDEN WRITES THE PLAIN NAME, THE RUNTIME READS THE PREFIXED ONE, AND THEY ARE
// NOT THE SAME VARIABLE. The attribute's expression is
// `_this setVariable ['droneClass',_value]` - no addon prefix, because that is
// what the module framework writes. Reading QGVAR(droneClass) here would have
// looked up jmfsb_cas_droneClass, found nothing, and used the default for
// every field on the module: a mission maker could have typed an airframe, a
// callsign and an airframe count into Eden and got the shipped defaults for
// all three, silently. Read plain, publish prefixed - which is what the
// enemy-drone module does and the reason it works.
private _cls = _logic getVariable ["droneClass", ""];
private _side = (call EFUNC(common,playerSides)) param [0, west];

// A BLANK CLASS IS THE SIDE'S OWN UCAV, not a refusal. A mission maker who
// wants "some CAS" and does not care which airframe should get CAS.
if (_cls isEqualTo "") then {
    _cls = switch (_side) do {
        case east: {"O_UAV_02_CAS_F"};
        case independent: {"I_UAV_02_CAS_F"};
        default {"B_UAV_02_CAS_F"};
    };
};

if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith {
    WARNING_1("module names airframe '%1', which is not a class in this mission - no asset placed",_cls);
};

// THE AIRFRAME MUST BE ABLE TO FLY THE RUN. A rotary or a ground class in
// this field is a module that would spawn something at 700 m and drop it,
// and the report would be "the CAS module does nothing".
if !(_cls isKindOf "Plane") exitWith {
    WARNING_1("airframe '%1' is not a fixed-wing class - this module flies aeroplanes; no asset placed",_cls);
};

private _callsign = _logic getVariable ["callsign", ""];
if (_callsign isEqualTo "") then {_callsign = "HAWK"};

// Everything the run and the support page need lives on the logic, public,
// so a client drawing the support page reads the same numbers the server
// flies the run with. Clamped here rather than at every use - a negative
// cooldown typed into Eden is a mistake, not a feature.
_logic setVariable [QGVAR(cls), _cls, true];
_logic setVariable [QGVAR(callsign), toUpper _callsign, true];
_logic setVariable [QGVAR(side), _side, true];
_logic setVariable [QGVAR(airframes), 0 max (_logic getVariable ["airframes", 3]), true];
_logic setVariable [QGVAR(spawnDistance), 500 max (_logic getVariable ["spawnDistance", 4000]), true];
_logic setVariable [QGVAR(altitude), 50 max (_logic getVariable ["altitude", 700]), true];
_logic setVariable [QGVAR(speed), 50 max (_logic getVariable ["speed", 400]), true];
_logic setVariable [QGVAR(spawnDelay), 0 max (_logic getVariable ["spawnDelay", 30]), true];
_logic setVariable [QGVAR(cooldown), 0 max (_logic getVariable ["cooldown", 300]), true];
_logic setVariable [QGVAR(searchRadius), 0 max (_logic getVariable ["searchRadius", 300]), true];

// Running state, published for the same reason: the support page reads status
// off these rather than asking the server every redraw.
_logic setVariable [QGVAR(lost), 0, true];
_logic setVariable [QGVAR(readyAt), 0, true];
_logic setVariable [QGVAR(status), "idle", true];
_logic setVariable [QGVAR(vehicle), objNull, true];

GVAR(entities) pushBack _logic;
_logic setVariable [QGVAR(id), count GVAR(entities) - 1, true];
// THE BOARD IS READ ON EVERY CLIENT. fnc_assets builds the rows locally, so a
// list kept only on the server gave every client on a dedicated server an empty
// CAS-drone board (found 2026-10-19). Published on each registration; JIP
// clients get the last value.
publicVariable QGVAR(entities);

INFO_3("asset '%1' on the board for %2 flying %3",toUpper _callsign,_side,_cls);
