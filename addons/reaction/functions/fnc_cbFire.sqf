#include "script_component.hpp"
/*
 * Author: YonV
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

// The first ALiVE commander hostile to the guns' side - without ALiVE, the
// mission's enemy (user, 2026-11-02). Without ALiVE there are no commander's
// guns to ask, so the virtual barrage below answers.
private _answering = ([_pside] call EFUNC(common,hostileCommander)) select 0;

private _asked = false;
// No commander's guns with ALiVE loaded but no commanders either (user,
// 2026-11-02: "same as not loaded").
if (_answering isNotEqualTo sideUnknown
    && {!isNil QEFUNC(adapter_alive,requestFire)}
    && {[] call EFUNC(common,aliveLoaded)}) then {
    _asked = [_answering, _pos, 1] call EFUNC(adapter_alive,requestFire);
};
if (!_asked) then {
    [_pos, GVAR(cbRounds), GVAR(cbSpread), CB_AMMO, GVAR(cbRounds) * CB_GAP] call EFUNC(common,fireBarrage);
};
// Hoisted: a comma inside a macro argument reads as an argument separator.
private _how = ["virtual barrage", "commander's guns"] select _asked;
INFO_2("counter-battery: firing on %1 (%2)",mapGridPosition _pos,_how);
