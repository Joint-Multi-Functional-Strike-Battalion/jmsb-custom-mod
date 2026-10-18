#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads the AA Base module and builds the base it describes - a radar, SAM
 * launchers round it and AA guns close in, inside the module's own area.
 *
 * THE MISSION MAKER CHOSE THE SPOT. Unlike the Air Defence module, nothing here
 * is read from ALiVE commanders or TAORs and there is NO TAOR GATE: the gate
 * exists to stop jmfsb siting things on the wrong side's ground by itself, and
 * a base placed by hand in Eden is not jmfsb's siting decision to refuse. This
 * module needs neither the Air Defence module nor any marker.
 *
 * NO SIDE ATTRIBUTE (D59). The base belongs to whoever owns its hardware: the
 * radar class's own config side, else the first launcher's, else the first
 * gun's. A base with no class that resolves to a side builds nothing.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, [], true] call jmfsb_airdefence_fnc_moduleAABase
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};

// A comma-separated class list, trimmed, with every class the game does not
// have named in the RPT and dropped - a typo is a WARNING, not a null object
// at createVehicle and a base that silently never appeared.
private _fnc_classes = {
    params ["_csv", "_what"];
    private _all = ((_csv splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};
    private _good = _all select {isClass (configFile >> "CfgVehicles" >> _x)};
    {
        WARNING_2("AA base: %1 class '%2' does not exist - skipped",_what,_x);
    } forEach (_all - _good);
    _good
};

private _radar = ([_logic getVariable ["radarClass", ""], "radar"] call _fnc_classes) param [0, ""];
private _missiles = [_logic getVariable ["missileClass", ""], "missile"] call _fnc_classes;
private _guns = [_logic getVariable ["gunClass", ""], "gun"] call _fnc_classes;
private _missileCount = round ((_logic getVariable ["missileCount", 3]) max 0);
private _gunCount = round ((_logic getVariable ["gunCount", 2]) max 0);
private _guards = round (((_logic getVariable ["guards", 1]) max 0) min AD_SEC_GROUPS_MAX);
private _guardClasses = [_logic getVariable ["guardClasses", ""], "guard"] call _fnc_classes;

// Classes that will not shoot at aircraft still get built - the mission maker
// asked for them - but the RPT says so, because a "gun" that ignores jets
// reads as a broken base.
{
    if (([_x] call FUNC(aaKind)) == 0) then {
        WARNING_1("AA base: '%1' carries no anti-air weapon - built anyway",_x);
    };
} forEach (_missiles + _guns);

// --- whose base: the hardware's own side ----------------------------------
private _side = sideUnknown;
private _faction = "";
{
    private _n = getNumber (configFile >> "CfgVehicles" >> _x >> "side");
    if (_n >= 0 && {_n < count AB_SIDES}) exitWith {
        _side = AB_SIDES select _n;
        _faction = getText (configFile >> "CfgVehicles" >> _x >> "faction");
    };
} forEach (([_radar] + _missiles + _guns) select {_x isNotEqualTo ""});

if (_side isEqualTo sideUnknown) exitWith {
    WARNING_1("AA base at %1: no radar, missile or gun class resolves to a side - nothing built",mapGridPosition _logic);
};

// Guards and any manned static's gunner: the named classes, else the
// hardware's own faction, else the side's plain soldier (FUNC(factionMen)).
private _kinds = if (_guardClasses isNotEqualTo []) then {_guardClasses} else {
    [_faction, _side] call FUNC(factionMen)
};

private _pos = getPosATL _logic;
_pos set [2, 0];
(_logic getVariable ["objectArea", [0, 0, 0, false, 0]]) params [
    ["_a", 0, [0]], ["_b", 0, [0]], ["_angle", 0, [0]], ["_isRect", false, [false]]
];
private _area = [_a, _b, _angle, _isRect];

// AFTER POSTINIT. Module functions run between preInit and postInit, and this
// addon's site list - and adsite's batteryUp handler - only exist once every
// postInit has run. Building now would write to a list postInit then wipes and
// raise an event nobody is listening for yet.
[{time > 0}, {
    _this call FUNC(buildAABase);
}, [_pos, _area, _side, _radar, _missiles, _missileCount, _guns, _gunCount, _guards, _kinds]]
    call CBA_fnc_waitUntilAndExecute;
