#include "script_component.hpp"
/*
 * Author: YonV
 * Applies proximity-burst effect and distance-scaled damage to all UAVs within
 * the lethal radius. Routes damage via remoteExec for non-local drones.
 *
 * These PAB rounds have no real explosive charge — the engine never fires a
 * native "Explode" event for them, so ACE's frag system (which only listens
 * for that event) would otherwise never trigger. If ACE_frag is present, its
 * fragmentation is invoked directly here at the scripted detonation point,
 * using the ammo class's ace_frag_* CfgAmmo values (a fabricated frag sleeve,
 * see CfgAmmo.hpp). If ACE_frag isn't loaded, this event dispatch is a no-op.
 *
 * Arguments:
 * 0: Projectile <OBJECT>
 * 1: Lethal radius in metres <NUMBER>
 * 2: Maximum damage at point blank (1.0 = guaranteed kill) <NUMBER>
 * 3: Burst position ASL (optional, default: the projectile's own position) <ARRAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [
    ["_proj",     objNull, [objNull]],
    ["_lethal",   5,       [0]],
    ["_dmg",      1.0,     [0]],
    ["_burstPos", [],      [[]]]
];

// Burst at the closest point of approach the tracker found (or the dialled
// airburst range), not at wherever the round has flown on to by the time the
// check fires - otherwise the falloff below returns zero on a fast round.
if (count _burstPos < 3) then { _burstPos = getPosASL _proj; };
private _bpos = ASLToAGL _burstPos;
"SmallSecondary" createVehicle _bpos;

if (missionNamespace getVariable ["ace_frag_enabled", true]) then {
    // ACE 3.21 frago takes [position ASL, ammo class].
    ["ace_frag_frag_eh", [_burstPos, typeOf _proj]] call CBA_fnc_serverEvent;
};

{
    private _f = 1 - ((_burstPos distance (getPosASL _x)) / _lethal);
    if (_f > 0) then {
        private _newDmg = (damage _x) + (_f * _dmg);
        if (local _x) then {
            _x setDamage _newDmg;
        } else {
            [_x, _newDmg] remoteExec ["setDamage", _x];
        };
    };
} forEach ((_bpos nearEntities [["Air", "UAV"], _lethal]) select { unitIsUAV _x });

deleteVehicle _proj;
