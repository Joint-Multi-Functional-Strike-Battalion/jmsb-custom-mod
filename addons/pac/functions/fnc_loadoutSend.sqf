#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_loadoutSend

Description:
    Finds the loadout a player kept for their current role, checks it
    against the role's arsenalWhitelist, and sends it to their machine to
    put on (FUNC(loadoutApply)). Server only; asked by the player's machine
    after the role's own default loadout has gone on, so this goes on top.

    VALIDATED ON LOAD, per the handoff. If the PAC role names an
    arsenalWhitelist, every class in the kept loadout that is not in it is
    blanked - weapon, attachment, item, container - and the player is told
    how many. An empty whitelist means no restriction.

    NO KEPT LOADOUT IS NOT AN ERROR. Most spawns will be that; the role's
    default stands and nothing is sent.

Parameters:
    0: The unit <OBJECT>

Returns:
    Whether a loadout was sent <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_unit", objNull, [objNull]]];

if (!isServer || isNull _unit) exitWith {false};
// A client asks only for his own kept loadout (review S5).
if !([_unit] call EFUNC(common,senderIs)) exitWith {false};
if ((GVAR(settings) getOrDefault ["savedLoadouts", 3]) isEqualTo 0) exitWith {false};

private _uid = [_unit] call FUNC(uid);
private _rec = GVAR(players) getOrDefault [_uid, createHashMap];
if (count _rec isEqualTo 0) exitWith {false};

private _roleId = _rec getOrDefault ["roleId", ""];
private _key = _roleId;
if (_key isEqualTo "") then {_key = _unit getVariable ["YMF_role", ""]};
if (_key isEqualTo "") exitWith {false};

private _loadouts = _rec getOrDefault ["loadouts", createHashMap];
if !(_loadouts isEqualType createHashMap) exitWith {false};
private _kept = _loadouts getOrDefault [_key, []];
if (count _kept < 2) exitWith {false};
private _loadout = +(_kept # 1);

// ---- whitelist -------------------------------------------------------------
private _white = ((GVAR(structure) getOrDefault ["roles", createHashMap]) getOrDefault [_roleId, createHashMap]) getOrDefault ["arsenalWhitelist", []];
private _dropped = 0;

if (_white isNotEqualTo []) then {
    private _allowed = _white apply {toLower _x};
    private _fnc_clean = {
        params ["_v"];
        switch (true) do {
            case (_v isEqualType ""): {
                if (_v isEqualTo "" || {(toLower _v) in _allowed}) exitWith {_v};
                // Not a class at all (a loadout also carries "" and numbers as
                // strings nowhere, but be safe): only blank things that are
                // real classes somebody could have restricted.
                if (isClass (configFile >> "CfgWeapons" >> _v) || {isClass (configFile >> "CfgMagazines" >> _v)} || {isClass (configFile >> "CfgVehicles" >> _v)} || {isClass (configFile >> "CfgGlasses" >> _v)}) exitWith {
                    _dropped = _dropped + 1;
                    ""
                };
                _v
            };
            case (_v isEqualType []): {_v apply {[_x] call _fnc_clean}};
            default {_v};
        };
    };
    _loadout = [_loadout] call _fnc_clean;
};

[_unit, _loadout, _dropped] remoteExec [QFUNC(loadoutApply), owner _unit];
TRACE_3("kept loadout sent",name _unit,_key,_dropped);

true
