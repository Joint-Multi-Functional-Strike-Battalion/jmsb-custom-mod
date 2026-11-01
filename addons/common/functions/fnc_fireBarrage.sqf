#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_common_fnc_fireBarrage

Description:
    Rains shells on a point. Shared so more than one feature
    can call for artillery without either of them owning the other: counter-battery
    uses it for its slow atmospheric drip, counter-battery for a heavy shoot on a
    captured objective. Neither addon requires the other.

    Rounds spawn high above scattered impact points and fall - a virtual battery,
    no gun on the map, nothing to destroy or run out of ammo.

Parameters:
    _pos    : ARRAY  - centre of the impact area.
    _rounds : NUMBER - how many shells. Optional, default 3.
    _spread : NUMBER - scatter radius in metres. Optional, default 50.
    _shell  : STRING - CfgAmmo class. Optional, default 155mm HE.
    _window : NUMBER - seconds to spread the rounds across. Optional; 0 uses the
                       legacy fixed gap.

Returns:
    BOOL - true if the mission was scheduled.

Example:
    [_objPos, 24, 150, "Sh_155mm_AMOS", 60] call jmfsb_common_fnc_fireBarrage

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_pos", [], [[]]], ["_rounds", 3, [0]], ["_spread", 50, [0]],
        ["_shell", "Sh_155mm_AMOS", [""]], ["_window", 0, [0]]];

if (!isServer) exitWith { false };
if (_pos isEqualTo [] || _shell isEqualTo "" || _rounds < 1) exitWith { false };

private _gap = if (_window > 0) then { _window / _rounds } else { BARRAGE_ROUND_GAP };

// SAID ON THE SERVER, so the enemy's counter-battery radar can report virtual
// fire like any gun's (jmfsb_reaction_fnc_cbVirtual; user, 2026-10-25: "all
// enemy shells"). Every caller of this is enemy fire on the players. Hooks
// from FUNC(onBarrage), not a CBA event any client could raise (review R1).
{
    [_pos, _rounds, _shell] call _x;
} forEach (localNamespace getVariable [QGVAR(barrageHooks), []]);

diag_log text format ["[JMSB] Barrage: %1x %2 -> grid %3 over %4s",
    round _rounds, _shell, mapGridPosition _pos, round (_gap * _rounds)];

for "_i" from 0 to ((round _rounds) - 1) do {
    [{
        params ["_tgt", "_spread", "_shell"];
        // sqrt of a uniform roll spreads impacts evenly across the disc rather
        // than bunching them at the centre.
        private _a = random 360;
        private _r = sqrt (random 1) * _spread;
        private _impact = [(_tgt select 0) + _r * sin _a, (_tgt select 1) + _r * cos _a];
        private _sp = [_impact select 0, _impact select 1, BARRAGE_SHELL_ALT];
        private _round = createVehicle [_shell, _sp, [], 0, "CAN_COLLIDE"];
        if (isNull _round) exitWith {};
        _round setPosATL _sp;
        _round setVectorDirAndUp [[0, 0, -1], [0, 1, 0]];
        _round setVelocity [0, 0, -BARRAGE_SHELL_SPEED];
    }, [_pos, _spread, _shell], _i * _gap] call CBA_fnc_waitAndExecute;
};

true
