#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: one evac, reached by remoteExec from FUNC(convert). Builds the
 * injured AI casualty clone and heals the player onto the medic. The server
 * can read the casualty's ACE medical vars (they are all broadcast) and owns
 * the AI it creates.
 *
 * THE SERVER TRUSTS NOTHING THE CLIENT SAYS (review S6). The medic is the
 * sending machine's own player (EFUNC(common,sender)), never a unit from the
 * arguments; he must be alive and beside the casualty, and FUNC(canConvert)
 * is run again here (downed living player, not himself, Medics Only). The
 * claim flag is the client's (it hides the action in the round trip); the
 * server keeps its own guard in localNamespace, so one casualty is not
 * evacuated twice by two medics in the same second. Without this, any
 * client could full-heal anyone anywhere.
 *
 * Arguments:
 * 0: The downed player being evacuated <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [cursorTarget] remoteExecCall ["jmfsb_evac_fnc_evacServer", 2]
 *
 * Public: No
 */

params [["_casualty", objNull, [objNull]]];

if (!isServer || {isNull _casualty}) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_medic"];
private _done = localNamespace getVariable [QGVAR(done), createHashMap];
// Keyed by Steam id: the casualty is always a player (FUNC(canConvert)).
private _key = getPlayerUID _casualty;
private _why = switch (true) do {
    case (isNull _medic || {!alive _medic}): {"no living medic"};
    case ((_medic distance _casualty) > EVAC_RANGE): {"not beside the casualty"};
    case (!([_medic, _casualty, true] call FUNC(canConvert))): {"not a casualty he may evacuate"};
    case (CBA_missionTime < ((_done getOrDefault [_key, -EVAC_GUARD]) + EVAC_GUARD)): {"already evacuated"};
    default {""};
};
if (_why isNotEqualTo "") exitWith {
    WARNING_3("evacServer: refused %1 from machine %2 - %3",_casualty,_owner,_why);
    _casualty setVariable [QGVAR(claimed), nil, true];
    if (!isNull _medic) then {
        ["Evac", "Failed.", EVAC_FAIL_COLOR] remoteExecCall [QEFUNC(notify,notify), _owner];
    };
};
_done set [_key, CBA_missionTime];
localNamespace setVariable [QGVAR(done), _done];

// -- snapshot the casualty's injuries so the clone matches exactly --
private _hitPoints = ["HitHead", "HitChest", "HitLeftArm", "HitRightArm", "HitLeftLeg", "HitRightLeg"];
private _hits = _hitPoints apply { [_x, _casualty getHitPointDamage _x] };

// The full ACE injury surface (same set fullHealLocal resets). openWounds /
// bandaged / stitched are hashMaps - deep-copied below so the clone never
// shares a reference with the casualty.
private _medVars = [
    "ace_medical_pain",
    "ace_medical_painSuppress",
    "ace_medical_inPain",
    "ace_medical_bloodVolume",
    "ace_medical_bloodPressure",
    "ace_medical_heartRate",
    "ace_medical_peripheralResistance",
    "ace_medical_spo2",
    "ace_medical_oxygenDemand",
    "ace_medical_woundBleeding",
    "ace_medical_openWounds",
    "ace_medical_bandagedWounds",
    "ace_medical_stitchedWounds",
    "ace_medical_tourniquets",
    "ace_medical_fractures",
    "ace_medical_bodyPartDamage",
    "ace_medical_isLimping",
    "ace_medical_inCardiacArrest",
    "ace_medical_ivBags"
];
private _med = [];
{
    private _val = _casualty getVariable _x;
    if (!isNil "_val") then {
        if (_val isEqualTypeAny [[], createHashMap]) then {
            _val = +_val;
        };
        _med pushBack [_x, _val];
    };
} forEach _medVars;

// -- spawn the AI casualty clone at the downed spot, same loadout --
private _type = typeOf _casualty;
private _side = side (group _casualty);
private _pos = getPosATL _casualty;
private _dir = getDir _casualty;
private _loadout = getUnitLoadout _casualty;

private _ai = (createGroup [_side, true]) createUnit [_type, _pos, [], 0, "CAN_COLLIDE"];
_ai setDir _dir;
_ai setUnitLoadout _loadout;
_ai setName (name _casualty);
_ai setVariable [QGVAR(isCasualtyAI), true, true];
// Per-unit override so ACE never auto-kills this AI just for being down.
_ai setVariable ["ace_medical_statemachine_AIUnconsciousness", true, true];

// -- apply the matching injuries + knock out, once ACE medical has settled --
[{
    params ["_ai", "_med", "_hits"];
    if (isNull _ai) exitWith {};

    {
        _x params ["_hp", "_dmg"];
        _ai setHitPointDamage [_hp, _dmg];
    } forEach _hits;
    {
        _x params ["_var", "_val"];
        _ai setVariable [_var, _val, true];
    } forEach _med;

    [_ai, true] call ace_medical_fnc_setUnconscious;
    _ai disableAI "ALL";
    _ai setUnitPos "DOWN";
    _ai setBehaviour "CARELESS";
}, [_ai, _med, _hits], EVAC_SETTLE] call CBA_fnc_waitAndExecute;

// -- fully heal the actual player and place them on the medic --
[_medic, _casualty] call ace_medical_treatment_fnc_fullHeal;
_casualty setVariable [QGVAR(claimed), nil, true];

private _rel = _medic getRelPos [EVAC_PLACE_DIST, EVAC_PLACE_DIR];
_casualty setPosATL [_rel select 0, _rel select 1, (getPosATL _medic) select 2];
