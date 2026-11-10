#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A, CPL.Dunn.W
 * The local half of Call Endex, sent to every machine by the server
 * (FUNC(endexRequest)) once it has checked the caller. AI orders need the
 * group local, and safety, healing and the hold-fire handler need the player,
 * so each machine does its own share. Taken only from the server (review S7).
 *
 * Arguments:
 * 0: Set player weapons to safe <BOOL>
 * 1: Pacify AI <BOOL>
 * 2: Hint players that fire <BOOL>
 * 3: Heal all players <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [true, true, true, true] remoteExecCall ["jmfsb_zenmodules_fnc_endexLocal", 0]
 *
 * Public: No
 */

params [
    ["_weaponsSafe", false, [false]],
    ["_aiPacified", false, [false]],
    ["_holdFireMessage", false, [false]],
    ["_healAllPlayers", false, [false]]
];

if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("ENDEX","refused - not from the server (machine %1)",remoteExecutedOwner);
};

// Groups this machine owns (server, headless client or Zeus); AI created
// after the endex is not affected.
if (_aiPacified) then {
    private _groups = [];
    {
        _groups pushBackUnique (group _x);
    } forEach (allUnits - allPlayers);
    {
        if (local _x) then {
            _x setBehaviourStrong "CARELESS";
            _x setCombatMode "BLUE";
            INFO_1("ENDEX","AI group %1 set to careless and blue.",_x);
        };
    } forEach _groups;
};

if (!hasInterface) exitWith {};

if (_weaponsSafe && {!isNil "ace_safemode_fnc_setWeaponSafety"}) then {
    [player, currentWeapon player, true] call ace_safemode_fnc_setWeaponSafety;
    INFO_2("ENDEX","Player %1 weapon %2 set to safe.",player,currentWeapon player);
};

if (_healAllPlayers && {!isNil "ace_medical_treatment_fnc_fullHealLocal"}) then {
    [player] call ace_medical_treatment_fnc_fullHealLocal;
    INFO_2("ENDEX","%1 [%2] has been healed.",player,typeOf player);
};

// Added once per client, after a grace period so rounds already in flight
// are not counted. The handler itself checks the endex is still on.
if (_holdFireMessage && {!GVAR(endexFiredAdded)}) then {
    GVAR(endexFiredAdded) = true;
    [{
        ["ace_firedPlayer", LINKFUNC(endexFired)] call CBA_fnc_addEventHandler;
        ["ace_firedPlayerVehicle", LINKFUNC(endexFired)] call CBA_fnc_addEventHandler;
    }, [], ENDEX_HOLDFIRE_DELAY] call CBA_fnc_waitAndExecute;
};
