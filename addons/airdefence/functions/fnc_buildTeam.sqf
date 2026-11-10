#include "script_component.hpp"
/*
 * Author: YonV
 * Builds one MANPAD team and profiles it.
 *
 * The men are the asymmetric commander's own - drawn from its faction, so they
 * look like the rest of its force rather than a squad of strangers standing on
 * a hill. Only the launcher is added.
 *
 * Arguments:
 * 0: Where <ARRAY>
 * 1: The side <SIDE>
 * 2: Launcher class <STRING>
 * 3: Magazine class <STRING>
 * 4: Man classes to draw from <ARRAY>
 *
 * Return Value:
 * It was built <BOOL>
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]],
        ["_weapon", "", [""]], ["_mag", "", [""]], ["_kinds", [], [[]]]];

if (_pos isEqualTo [] || _weapon isEqualTo "") exitWith {false};

// The common pre-spawn gate - a MANPAD team stands on its own ground or
// not at all (adapter TAOR; no TAOR, no gate).
if (!([_side, _pos, "manpad team"] call EFUNC(common,taorGate))) exitWith {false};

if (_kinds isEqualTo []) exitWith {
    WARNING_1("no infantry class known for %1 - no MANPAD team",_side);
    false
};

private _grp = createGroup [_side, true];
if (isNull _grp) exitWith {false};

private _n = AD_TEAM_MIN + floor random (AD_TEAM_MAX - AD_TEAM_MIN + 1);

private _men = [];
for "_i" from 1 to _n do {
    private _at = _pos getPos [random 12, random 360];
    private _u = _grp createUnit [selectRandom _kinds, _at, [], 0, "CAN_COLLIDE"];
    if (!isNull _u) then { _men pushBack _u };
};

if (_men isEqualTo []) exitWith {
    deleteGroup _grp;
    false
};

// The shooter carries it; the rest carry reloads. A team of three men all
// firing at once wastes the whole team on one aircraft.
//
// A man class that already carries an AA launcher of its own KEEPS it - the
// weapon field is for men who come without one, not a second tube for the
// specialist - and the team's reloads then match his launcher, not the field.
private _shooter = _men select 0;
private _teamMag = _mag;

private _own = secondaryWeapon _shooter;
private _ownIsAa = _own isNotEqualTo "" && {
    (getArray (configFile >> "CfgWeapons" >> _own >> "magazines")) findIf {
        private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
        getNumber (configFile >> "CfgAmmo" >> _ammo >> "airLock") > 0
    } > -1
};

if (_ownIsAa) then {
    _teamMag = (getArray (configFile >> "CfgWeapons" >> _own >> "magazines")) param [0, ""];
} else {
    // magazine before weapon, so the tube comes up loaded
    if (_teamMag isNotEqualTo "") then { _shooter addMagazine _teamMag };
    _shooter addWeapon _weapon;
};

if (_teamMag isNotEqualTo "") then {
    _shooter addMagazine _teamMag;
    { _x addMagazine _teamMag } forEach (_men select [1, count _men - 1]);
};

// They hold their ground rather than wandering: a team that walks away from
// the approach it was placed to cover is not covering anything.
_grp setBehaviour "COMBAT";
_grp setCombatMode "YELLOW";

[{
    params ["_grp", "_side", "_pos"];
    if (isNull _grp) exitWith {};

    // NOT PROFILED - see the note in FUNC(buildBattery). ALiVE's runtime
    // profiler deletes what it is handed, so a MANPAD team offered to it was
    // a team that stopped existing.
    // Guarded: without ALiVE there is nobody to tell (user, 2026-11-02).
    if (!isNil QEFUNC(adapter_alive,profileIgnore)) then {
        [_grp] call EFUNC(adapter_alive,profileIgnore);
    };

    INFO_2("MANPAD team up for %1 at %2",_side,mapGridPosition _pos);
}, [_grp, _side, _pos]] call CBA_fnc_execNextFrame;

GVAR(teams) pushBack [+_pos, _side];

true
