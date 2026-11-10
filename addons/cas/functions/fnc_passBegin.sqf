#include "script_component.hpp"
/*
 * Author: YonV
 * Begins one attack pass on an aim point - a jet's, a helicopter's or a
 * drone's (2026-11-05, modelled on how Simplex Support Services flies a
 * strafe; no code of it used). The owner's watch ticks it (FUNC(passTick))
 * until it reports the pass over; the dive itself is flown every frame
 * (FUNC(passFrame)). The PASS_ defines in script_component.hpp say how.
 *
 * WHAT IT FIRES is picked now (FUNC(pickStore): the store asked for on the
 * airframe as QGVAR(ordnance), else the heaviest aboard) and read off the
 * config: its muzzle speed (a rocket's at burnout), its air friction, how it
 * is steered - by its seeker (KIND_GUIDED, the dummy laser target), a bomb
 * released at the airframe's speed (KIND_BOMB, flown to the aim), or a shell
 * on a ballistic arc (KIND_SHELL) - the fire mode's reload, and the salvo one
 * pass puts down. The magazine is loaded on its turret now.
 *
 * THE GEOMETRY is worked from the airframe: its run speed, the release
 * range, the commit distance the dive begins inside, the nearest it may
 * commit, and the line-up distance it must be on the ingress bearing by.
 * The first order goes now: to the aim when it is already on the line, else
 * to the prep point out on the bearing. A helicopter lines up at
 * PASS_HELI_HEIGHT m; a plane at the height its owner gave it.
 *
 * THE CREW'S OWN TARGETING is switched off for the pass and put back after
 * (FUNC(passEnd)) - a SAD crew let off the leash would pick its own fight in
 * the dive. A pass already under way is ended first.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: The aim point, ATL <ARRAY>
 * 2: An object the aim follows - a laser spot - objNull for a fixed point <OBJECT>
 * 3: The ingress bearing, from the aim towards where it comes in from <NUMBER>
 * 4: Options <HASHMAP> (optional, default empty):
 *      "order"  <CODE> how the owner orders the airframe to a point, [aircraft, point]; called with [] for the point when the dive takes over - the owner drops any order of its own. Default: doMove
 *      "search" <ARRAY> [grid, radius, side, friendly range, danger close] - looked at for a laser or smoke on the way in while the grid is all it has; [] for none
 *      "by"     <STRING> what guides the aim now: "laser", "smoke", "known", "grid"
 *      "height" <NUMBER> the height to line up at, m ATL; absent: a helicopter PASS_HELI_HEIGHT, a plane its own
 *
 * Return Value:
 * Begun - false when nothing aboard can hit the ground, or the airframe is not the server's to fly <BOOL>
 *
 * Example:
 * [_veh, _pos, objNull, 270, createHashMap] call jmfsb_cas_fnc_passBegin
 *
 * Public: Yes
 */

params [
    ["_veh", objNull, [objNull]],
    ["_aim", [], [[]]],
    ["_track", objNull, [objNull]],
    ["_inDir", 0, [0]],
    ["_opts", createHashMap, [createHashMap]]
];

if (!alive _veh || !local _veh || !canMove _veh || count _aim < 2) exitWith {false};
private _pilot = driver _veh;
if (isNull _pilot) exitWith {false};
if ([_veh] call FUNC(passActive)) then {[_veh, "replaced by a new pass", "", true] call FUNC(passEnd)};

// THE STORE.
private _want = _veh getVariable [QGVAR(ordnance), ""];
if !(_want isEqualType "") then {_want = ""};
private _store = [_veh, _want] call FUNC(pickStore);
if (_store isEqualTo []) exitWith {false};
_store params ["_weapon", "_mag", "_turret"];

private _cfgWeapon = configFile >> "CfgWeapons" >> _weapon;
private _cfgMag = configFile >> "CfgMagazines" >> _mag;
private _cfgAmmo = configFile >> "CfgAmmo" >> getText (_cfgMag >> "ammo");
private _initSpeed = getNumber (_cfgMag >> "initSpeed");
private _weaponSpeed = getNumber (_cfgWeapon >> "initSpeed");
if (_weaponSpeed > 0) then {_initSpeed = _weaponSpeed};
if (_weaponSpeed < 0) then {_initSpeed = _initSpeed * -_weaponSpeed};
private _sim = toLower getText (_cfgAmmo >> "simulation");
private _friction = getNumber (_cfgAmmo >> "airFriction");
// A rocket's speed is its burnout speed and it flies flat enough at a run's
// range; its drag is in the engine's own units and is left out.
if (_sim in ["shotrocket", "shotmissile"]) then {
    _initSpeed = _initSpeed + (getNumber (_cfgAmmo >> "thrust")) * (getNumber (_cfgAmmo >> "thrustTime"));
    _friction = 0;
};
private _guided = (getNumber (_cfgAmmo >> "laserLock")) + (getNumber (_cfgAmmo >> "irLock")) + (getNumber (_cfgAmmo >> "nvLock")) > 0;
private _kind = KIND_SHELL;
if (_guided) then {_kind = KIND_GUIDED};
if (!_guided && _initSpeed <= 0) then {_kind = KIND_BOMB};
// A bomb's fall from the attack height is longer than the config's life of
// some bombs: the solution flies it to the ground regardless.
private _ttl = getNumber (_cfgAmmo >> "timeToLive");
if (_ttl <= 0 || _kind isEqualTo KIND_BOMB) then {_ttl = PASS_SIM_MAX_S};
private _mode = (getArray (_cfgWeapon >> "modes")) param [0, "this"];
if (_mode isEqualTo "this") then {_mode = _weapon};
private _gap = (getNumber (_cfgWeapon >> _mode >> "reloadTime")) max PASS_PULL_MIN_GAP;
private _salvo = switch (_kind) do {
    case KIND_GUIDED: {PASS_SALVO_GUIDED};
    case KIND_BOMB: {PASS_SALVO_BOMB};
    default {[-1, PASS_SALVO_ROCKET] select (_sim isEqualTo "shotrocket")};
};
private _burst = [0, PASS_GUN_BURST_S] select (_salvo < 0);
private _salvoTime = [_salvo * _gap, _burst] select (_salvo < 0);

// THE GEOMETRY.
private _heli = _veh isKindOf "Helicopter";
private _maxSpeed = (getNumber (configOf _veh >> "maxSpeed")) / KMH_PER_MS;
private _runSpeed = if (_heli) then {
    (_maxSpeed * PASS_HELI_SPEED_SHARE) min PASS_HELI_SPEED
} else {
    ((_maxSpeed * PASS_SPEED_SHARE) min PASS_PLANE_SPEED_MAX) max (PASS_STALL_MARGIN * (getNumber (configOf _veh >> "stallSpeed")) / KMH_PER_MS)
};
private _minSpeed = [PASS_STALL_MARGIN * (getNumber (configOf _veh >> "stallSpeed")) / KMH_PER_MS, PASS_HELI_MIN_SPEED] select _heli;
private _range = [PASS_PLANE_RANGE, PASS_HELI_RANGE] select _heli;
private _aimASL = ATLToASL [_aim select 0, _aim select 1, 0];
private _buffer = PASS_HEIGHT_SHARE * ((((getPosASL _veh) select 2) - (_aimASL select 2)) max 0);
private _commit = _range max (_runSpeed * (_salvoTime + PASS_DIVE_LEAD_S) + _buffer);
private _nearest = (_range * PASS_NEAREST_SHARE) max (_runSpeed * (_salvoTime + PASS_NEAREST_LEAD_S));
private _lineUp = (_range + PASS_LINE_EXTRA) max (_maxSpeed * (_salvoTime + PASS_LINE_LEAD_S) + _buffer);

// THE DUMMY the seeker locks and the turret looks at - the side's own laser
// class, so the airframe's ordnance accepts it; on a spot it rides the spot.
private _laserType = ["LaserTargetE", "LaserTargetW"] select ([side group _pilot, west] call BIS_fnc_sideIsFriendly);
private _dummy = createVehicle [_laserType, [0, 0, 0], [], 0, "CAN_COLLIDE"];
if (isNull _track) then {
    _dummy setPosATL [_aim select 0, _aim select 1, CAS_DUMMY_UP];
} else {
    _dummy attachTo [_track, [0, 0, CAS_DUMMY_UP]];
};

// THE MAGAZINE on its turret.
(weaponState [_veh, _turret, _weapon]) params ["", "", "", ["_loadedMag", "", [""]]];
if (_loadedMag isNotEqualTo _mag) then {_veh loadMagazine [_turret, _weapon, _mag]};

// THE CREW'S TARGETING OFF, remembered for after.
private _ai = [];
{
    _ai pushBack [_x, _x checkAIFeature "TARGET", _x checkAIFeature "AUTOTARGET"];
    _x disableAI "TARGET";
    _x disableAI "AUTOTARGET";
} forEach ((crew _veh) select {alive _x && !isPlayer _x});

private _height = (getPosATL _veh) select 2;
private _lineHeight = _opts getOrDefault ["height", [_height, PASS_HELI_HEIGHT] select _heli];
_veh flyInHeight _lineHeight;

// EVERY ROUND IS COUNTED AND STEERED: a seeker onto the dummy, a bomb flown
// to the aim; the gun and rockets go where the nose was put.
private _firedEH = _veh addEventHandler ["Fired", {
    params ["_veh", "", "", "", "", "_mag", "_projectile"];
    private _st = _veh getVariable [QGVAR(pass), createHashMap];
    if (count _st isEqualTo 0 || _mag isNotEqualTo (_st get "mag")) exitWith {};
    private _n = (_st getOrDefault ["fired", 0]) + 1;
    _st set ["fired", _n];
    private _dummy = _st get "dummy";
    private _aimASL = if (alive _dummy) then {getPosASL _dummy} else {_st get "aimASL"};
    switch (_st get "kind") do {
        case KIND_GUIDED: {
            if (isNull _projectile) exitWith {};
            if !(alive _dummy && {_projectile setMissileTarget _dummy}) then {
                _projectile setMissileTargetPos (ASLToAGL _aimASL);
            };
        };
        case KIND_BOMB: {
            [_projectile, _aimASL, _st get "friction"] call FUNC(bombDrop);
        };
    };
    // Each bomb, missile or rocket is said; a gun burst is counted at the end.
    if ((_st get "salvo") > 0) then {
        INFO_5("pass: '%1' releases %2 %3 of %4 - %5 m from the aim",typeOf _veh,_mag,_n,_st get "salvo",round ((getPosASL _veh) distance _aimASL));
    };
}];

_veh setVariable [QGVAR(pass), createHashMapFromArray [
    ["phase", PASS_LINE],
    ["began", CBA_missionTime],
    ["aim", [_aim select 0, _aim select 1, 0]],
    ["aimASL", _aimASL],
    ["track", _track],
    ["dummy", _dummy],
    ["by", _opts getOrDefault ["by", "grid"]],
    ["search", _opts getOrDefault ["search", []]],
    ["nextLook", CBA_missionTime + PASS_LOOK_EVERY],
    ["inDir", _inDir],
    ["order", _opts getOrDefault ["order", {
        params ["_veh", "_pos"];
        if (_pos isNotEqualTo []) then {_veh doMove _pos};
    }]],
    ["ordered", -1],
    ["orderTo", []],
    ["orderLogged", -PASS_ORDER_LOG_S],
    ["capped", false],
    ["weapon", _weapon],
    ["mag", _mag],
    ["turret", _turret],
    ["kind", _kind],
    ["initSpeed", _initSpeed],
    ["friction", _friction],
    ["ttl", _ttl],
    ["gap", _gap],
    ["salvo", _salvo],
    ["burst", _burst],
    ["fired", 0],
    ["pulls", 0],
    ["heli", _heli],
    ["runSpeed", _runSpeed],
    ["minSpeed", _minSpeed],
    ["range", _range],
    ["commit", _commit],
    ["nearest", _nearest],
    ["lineUp", _lineUp],
    ["height", _height],
    ["ai", _ai],
    ["firedEH", _firedEH],
    ["pfh", -1]
]];

private _salvoText = [str _salvo, format ["%1 s", _burst]] select (_salvo < 0);
INFO_8("pass: '%1' %2 (%3, %4) on %5 from %6 deg - line up by %7 m, dive from %8 m",typeOf _veh,_mag,_kind,_salvoText,mapGridPosition _aim,round _inDir,round _lineUp,round _commit);

// The first order now, not a tick later.
[_veh] call FUNC(passTick);
true
