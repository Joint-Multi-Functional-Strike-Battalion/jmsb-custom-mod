#include "script_component.hpp"
/*
 * Author: YonV
 * Stands the chain up: find the asymmetric commander, chart its safe houses,
 * put three leaders in them, place the internet pops, and start the rotation
 * and the prison watch.
 *
 * A map with no asymmetric commander gets no chain AND SAYS SO. Without ALiVE
 * the placed module stands for that commander (FUNC(moduleController)). A campaign
 * that already spent leaders does not get them back - the saved state is read
 * first, and a leader marked spent is never respawned (rule 5: finite).
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

// Once. The adapter's ready event fires a single time today, but qrf's
// listener is written for it firing again - if that day comes, a second
// pass here would stand up a SECOND chain: six leaders, doubled pops, two
// rotation clocks. qrf re-gathers safely; this does not, so it refuses.
if (GVAR(leaders) isNotEqualTo []) exitWith {};

// ALiVE loaded with no commanders is not loaded (user, 2026-11-02: "same as
// not loaded"): this runs from the adapter's fallback then, and takes the
// branch below.
private _alive = [] call EFUNC(common,aliveLoaded);
if (isNil QEFUNC(adapter_alive,commanders) || {!_alive}) then {
    // WITHOUT ALiVE (user, 2026-11-02: "works with or without"): the placed
    // module says this is an insurgency. The side is the man synchronised to
    // it, else the mission's enemy; the faction his, else the one that side's
    // men on the map wear.
    private _man = missionNamespace getVariable [QGVAR(syncedMan), objNull];
    GVAR(asymSide) = [call EFUNC(common,enemySide), side group _man] select (!isNull _man);
    GVAR(asymFaction) = [GVAR(asymSide), _man] call EFUNC(common,sideFaction);
    INFO_2("no ALiVE - the chain is %1's, faction '%2'",GVAR(asymSide),GVAR(asymFaction));
} else {
    {
        _x params ["_side", "_ctype"];
        if (_ctype isEqualTo "asymmetric") exitWith { GVAR(asymSide) = _side };
    } forEach (call EFUNC(adapter_alive,commanders));
};

if (GVAR(asymSide) isEqualTo sideUnknown) exitWith {
    INFO("no asymmetric commander on this map - the leader chain stays down");
};

GVAR(houses) = [] call FUNC(safeHouses);
if (count GVAR(houses) < LEADERS_COUNT) exitWith {
    INFO_1("only %1 safe house(s) found - the chain needs at least three",count GVAR(houses));
};

// What the campaign already spent.
private _spent = [];
// Kept in ALiVE's persistence; without ALiVE a mission starts with all three.
if (_alive && {!isNil QEFUNC(adapter_alive,getData)}) then {
    private _saved = [QGVAR(spent)] call EFUNC(adapter_alive,getData);
    if (!isNil "_saved" && {_saved isEqualType []}) then { _spent = _saved };
};

for "_i" from 0 to (LEADERS_COUNT - 1) do {
    if (_i in _spent) then {
        GVAR(leaders) pushBack [objNull, -1, "dead", 0];
        INFO_1("leader %1 was already spent - not replaced",_i + 1);
    } else {
        GVAR(leaders) pushBack ([_i] call FUNC(spawnLeader));
    };
};

missionNamespace setVariable [QGVAR(upCount),
    {(_x select 2) isEqualTo "up"} count GVAR(leaders), true];

[] call FUNC(placePops);
[] call FUNC(prisonWatch);

[{ [] call FUNC(rotate) }, GVAR(rotateEvery), []] call CBA_fnc_addPerFrameHandler;

private _up = {(_x select 2) isEqualTo "up"} count GVAR(leaders);
INFO_3("chain up: %1 leader(s) on %2 across %3 safe house(s)",
    _up,GVAR(asymSide),count GVAR(houses));
