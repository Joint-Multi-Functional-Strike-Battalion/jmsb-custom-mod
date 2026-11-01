#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the enemy's counter-battery answer on a fixed player battery
 * (FUNC(cbShot)). Asked of a hostile commander's own guns first, the way a
 * major reaction is (FUNC(major)); with no commander to ask, a virtual barrage.
 *
 * NO TAOR GATE, unlike the reaction fallback: counter-battery's whole job is to
 * reach the guns where they stand, and the players' guns stand in their own
 * base. The enemy reaching there is the point of the system.
 *
 * Arguments:
 * 0: Where the battery was at the fix, ATL <ARRAY>
 * 1: The firing players' side <SIDE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_pos, west] call jmfsb_reaction_fnc_cbFire
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_pside", sideUnknown, [sideUnknown]]];

if (!isServer || {_pos isEqualTo []}) exitWith {};

// The players at the guns hear it coming (cbWarn): told now, while the shells
// are in the air.
if (GVAR(cbWarn) > 0) then {
    private _near = allPlayers select {alive _x && {_x distance2D _pos <= CB_WARN_RADIUS}};
    if (_near isNotEqualTo []) then {
        ["COUNTER-BATTERY", "Incoming - the enemy has your guns. Move.", NOTE_BAD, _near] call EFUNC(notify,broadcast);
    };
};

private _answering = sideUnknown;
if (!isNil "jmfsb_adapter_alive_fnc_commanders") then {
    {
        _x params ["_cside"];
        if (_cside getFriend _pside < 0.6) exitWith {_answering = _cside};
    } forEach (call jmfsb_adapter_alive_fnc_commanders);
};

private _asked = false;
if (_answering isNotEqualTo sideUnknown && {!isNil "jmfsb_adapter_alive_fnc_requestFire"}) then {
    _asked = [_answering, _pos, 1] call jmfsb_adapter_alive_fnc_requestFire;
};
if (!_asked) then {
    [_pos, GVAR(cbRounds), GVAR(cbSpread), CB_AMMO, GVAR(cbRounds) * CB_GAP] call EFUNC(common,fireBarrage);
};
// Hoisted: a comma inside a macro argument reads as an argument separator.
private _how = ["virtual barrage", "commander's guns"] select _asked;
INFO_2("counter-battery: firing on %1 (%2)",mapGridPosition _pos,_how);
