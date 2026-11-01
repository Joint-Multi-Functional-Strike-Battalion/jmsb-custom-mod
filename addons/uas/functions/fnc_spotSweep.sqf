#include "script_component.hpp"
/*
 * Author: JMSB
 * A drone that has actually SEEN somebody says so, down the same path a
 * failed hack takes (new.md section 1.3 - one reaction path, no special
 * case). The listener is the reaction ladder; until that exists this raise is
 * a no-op, which is why it is written as an event rather than a call.
 *
 * knowsAbout rather than distance: a drone that flew over without noticing
 * anything reports nothing, and a section that stayed still and cold is not
 * punished for being overflown.
 *
 * Only REAL drones can see - a profiled one is a record and has no sensors -
 * so this walks live aircraft rather than any registry, which also means it
 * covers drones ALiVE put up as well as jmfsb's own.
 *
 * Parameters (CBA PFH): 0: args, 1: handle
 *
 * Public: No
 */

private _players = allPlayers select {alive _x && {!isObjectHidden _x}};
if (_players isEqualTo []) exitWith {};

{
    private _veh = _x;
    if (!alive _veh) then {continue};
    if (CBA_missionTime < (_veh getVariable [QGVAR(spotCd), -1e9])) then {continue};

    private _vside = side _veh;
    private _seen = objNull;
    {
        if ((_vside getFriend (side group _x)) < 0.6
            && {_x distance2D _veh < UAS_SPOT_RANGE}
            && {(_veh knowsAbout _x) >= UAS_SPOT_KNOWS}) exitWith { _seen = _x };
    } forEach _players;

    if (isNull _seen) then {continue};

    _veh setVariable [QGVAR(spotCd), CBA_missionTime + UAS_SPOT_COOLDOWN];
    // Straight into the detection roll (review R1: no CBA event to fake).
    if (!isNil QEFUNC(reaction,roll)) then {[_seen, "drone"] call EFUNC(reaction,roll)};

    INFO_2("drone %1 has eyes on %2",typeOf _veh,name _seen);

    // ARTILLERY ON DETECTION, if the module that launched this one asked for it.
    // The zone tag is stamped at creation - see FUNC(topUp).
    //
    // IT IS THE SPOTTER'S OWN COOLDOWN THAT PACES THE FIRST HALF, and the
    // zone's that paces the rest: one drone cannot call two missions a minute,
    // and two drones from the same module cannot either. Without the second
    // clock a zone with four airframes over one section is four fire missions.
    private _zone = _veh getVariable [QGVAR(zone), -1];
    if (_zone < 0) then {continue};

    private _zones = missionNamespace getVariable [QGVAR(zones), []];
    if (_zone >= count _zones) then {continue};

    ((_zones select _zone) param [5, [false, 6, 100, 300]]) params
        [["_on", false], ["_rounds", 6], ["_scatter", 100], ["_cooldown", 300]];

    if (!_on) then {continue};

    private _last = GVAR(artyLast) getOrDefault [_zone, -1e9];
    if (CBA_missionTime - _last < _cooldown) then {continue};
    GVAR(artyLast) set [_zone, CBA_missionTime];

    // WHERE IT WAS SEEN, not where it is when the shells land - the same rule
    // the jammer sites answer on. Moving is the counter.
    private _at = getPosATL _seen;

    INFO_3("drone patrol %1 calling %2 rounds on %3",_zone,_rounds,mapGridPosition _at);

    [_at, _rounds, _scatter, "Sh_155mm_AMOS", 30] call EFUNC(common,fireBarrage);
} forEach (vehicles select {_x isKindOf "UAV" && {alive _x}});
