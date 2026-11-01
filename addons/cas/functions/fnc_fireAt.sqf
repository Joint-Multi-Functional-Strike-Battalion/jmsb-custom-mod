#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the drone's ordnance on the aim point.
 *
 * THE AI PILOT IS NOT ASKED, AND THAT IS THE DESIGN. Arma's air AI decides for
 * itself whether it likes a target, and a CAS run that depends on it is a CAS
 * run that sometimes orbits the objective without firing - which is the single
 * most reported failure of every AI-driven support script ever written. The
 * group flies CARELESS with targeting switched off; this function is the only
 * thing that pulls a trigger, so the strike either happens or logs why not.
 *
 * A DUMMY LASER TARGET IS WHAT THE ORDNANCE ACTUALLY FOLLOWS. Simplex reached
 * the same answer and for the same reason: guided ordnance released at a
 * position argument will still wander, but a real LaserTarget object is
 * something the missile's own seeker locks. One is created at the aim point,
 * the Fired handler pins each projectile to it, and both are cleaned up after.
 * On a moving laser spot the dummy is attached, so a designator walking the
 * strike onto a vehicle walks the bomb with it.
 *
 * IT SHOOTS WHAT THE AIRFRAME HAS. No pylon config and no ordnance list on the
 * module: the aircraft in the field is asked what it is carrying. Unasked, it
 * uses the heaviest air-to-ground thing aboard; asked for a store BY NAME on
 * the support page - the page offers the airframe's own, see FUNC(stores) - it
 * uses that one. A mission that wants a different loadout gives the module a
 * different airframe class, which is the honest way to say it.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Aim point <ARRAY> - ATL
 * 2: Object to track, objNull for a fixed point <OBJECT>
 *
 * Return Value:
 * Something was fired <BOOL>
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_aim", [], [[]]], ["_track", objNull, [objNull]]];

if (isNull _veh || {!alive _veh} || {_aim isEqualTo []}) exitWith {false};
if (_veh getVariable [QGVAR(fired), false]) exitWith {false};

// PICK THE WEAPON ONCE, BY WEIGHT. Bombs and missiles first because they are
// what a strike is for; the gun is the fallback so an airframe carrying only
// cannon still makes a run rather than flying over silently.
private _rank = CAS_RANK;

// UNLESS THE CALLER ASKED FOR ONE OF THEM BY NAME. The page offered this
// airframe's own stores and sent back which one; FUNC(task) turned that into a
// magazine class before the order left the client, so what arrives here is a
// thing the aircraft is hung with rather than a category to go looking for.
// Empty is AUTO, which is the default and the common case.
private _want = _veh getVariable [QGVAR(ordnance), ""];
if !(_want isEqualType "") then {_want = ""};

private _fnc_bestOf = {
    params ["_want"];

    private _best = [];
    private _bestRank = -1;

    {
        private _turret = _x;
        private _loaded = _veh magazinesTurret _turret;
        {
            private _weapon = _x;
            // Only magazines this weapon can actually chamber. A pylon's bombs
            // and the gun's belt are both aboard; pairing one with the other
            // names a weapon that will never fire and the run goes in dry.
            private _fits = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
            {
                if !(_x in _fits) then {continue};
                if (_want isNotEqualTo "" && _x isNotEqualTo _want) then {continue};
                private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
                if (_ammo isEqualTo "") then {continue};
                private _sim = toLower getText (configFile >> "CfgAmmo" >> _ammo >> "simulation");
                private _r = _rank find _sim;
                if (_r < 0) then {continue};
                // The rank list is heaviest-first, so a LOWER index is the
                // better weapon and the first entry found at that index wins.
                if (_bestRank < 0 || _r < _bestRank) then {
                    _bestRank = _r;
                    _best = [_weapon, _x, _turret];
                };
            } forEach _loaded;
        } forEach (_veh weaponsTurret _turret);
    } forEach ([[-1]] + (allTurrets _veh));

    _best
};

private _best = [_want] call _fnc_bestOf;

// ASKED FOR AND NOT ABOARD IS NOT A REASON TO FLY OVER DRY. The section called
// for a strike; the kind of ordnance was a preference, and an airframe that
// cannot honour it still has something to shoot. Said in the log so a module
// pointed at an airframe that never carries what the page keeps offering is
// visible rather than mysterious.
if (_best isEqualTo [] && _want isNotEqualTo "") then {
    WARNING_2("'%1' has no '%2' left aboard - falling back to the heaviest thing it still has",typeOf _veh,_want);
    _best = [""] call _fnc_bestOf;
};

if (_best isEqualTo []) exitWith {
    WARNING_1("'%1' is carrying nothing it can shoot at the ground - the run goes in dry",typeOf _veh);
    false
};

_best params ["_weapon", "_mag", "_turret"];
_veh setVariable [QGVAR(fired), true];

// The dummy the seeker follows. Own side's laser class so the aircraft's own
// ordnance will accept it.
private _side = side group _veh;
private _laserType = ["LaserTargetE", "LaserTargetW"] select ([_side, west] call BIS_fnc_sideIsFriendly);
private _dummy = createVehicle [_laserType, [0, 0, 0], [], 0, "CAN_COLLIDE"];

if (isNull _track) then {
    _dummy setPosATL (_aim vectorAdd [0, 0, CAS_DUMMY_UP]);
} else {
    _dummy attachTo [_track, [0, 0, CAS_DUMMY_UP]];
};

_veh setVariable [QGVAR(dummy), _dummy];

// EVERY ROUND IS STEERED, not just the first. A salvo released at speed will
// otherwise spread across the field behind the target.
_veh setVariable [QGVAR(firedEH), _veh addEventHandler ["Fired", {
    params ["_unit", "", "", "", "", "", "_projectile"];
    private _dummy = _unit getVariable [QGVAR(dummy), objNull];
    if (isNull _dummy || {isNull _projectile}) exitWith {};
    _projectile setMissileTargetPos (getPosATL _dummy);
    if !(_projectile setMissileTarget _dummy) then {
        _projectile setMissileTargetPos (getPosATL _dummy);
    };
}]];

// fireAtTarget on the VEHICLE, not on a turret unit. A UAV's gunner seat may
// be empty or held by an AI agent that is not queryable this frame, and
// turretUnit on an empty seat is objNull - which fires nothing and reports
// nothing. The vehicle form picks its own gunner.
_veh doWatch _aim;
// Not proven for pylon stores (review B18): when the vehicle form refuses,
// the crewman on the store's turret is made to fire it instead. A mode of
// "this" means the weapon itself is the mode.
if !(_veh fireAtTarget [_dummy, _weapon]) then {
    private _shooter = [_veh turretUnit _turret, driver _veh] select (_turret isEqualTo [-1]);
    private _fireMode = (getArray (configFile >> "CfgWeapons" >> _weapon >> "modes")) param [0, "this"];
    if (_fireMode == "this") then {_fireMode = _weapon};
    if (isNull _shooter) exitWith {
        WARNING_2("'%1' could not fire %2 - no crewman on that store",typeOf _veh,_weapon);
    };
    _shooter forceWeaponFire [_weapon, _fireMode];
};

INFO_3("'%1' releasing %2 at %3",typeOf _veh,_weapon,mapGridPosition _aim);

// The dummy has done its job once the ordnance is away and guiding; leaving it
// lit would give every OTHER guided round in the air the same aim point.
[{
    params ["_veh", "_dummy"];
    if (!isNull _veh) then {
        _veh removeEventHandler ["Fired", _veh getVariable [QGVAR(firedEH), -1]];
        _veh setVariable [QGVAR(dummy), objNull];
    };
    if (!isNull _dummy) then {
        detach _dummy;
        deleteVehicle _dummy;
    };
}, [_veh, _dummy], 20] call CBA_fnc_waitAndExecute;

true
