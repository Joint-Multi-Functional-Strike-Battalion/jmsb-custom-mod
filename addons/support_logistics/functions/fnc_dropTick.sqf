#include "script_component.hpp"
/*
 * Author: YonV
 * The watch on one AIRDROP aircraft, every DROP_TICK seconds - the run-in
 * on Simplex Support Services' method (2026-11-05; no code of it used): a
 * straight line through the point and on past it, the stick put out one
 * item at a time from a release point short of it, then home:
 *
 *   "in"    flying the leg in, pointed OVERFLY past the point, coming from
 *           its transit height to the drop height on the support core's
 *           slope (EFUNC(support,approachHeight), 2026-11-01) - the height
 *           given to the AI only when it changes, so the shared controller's
 *           climb of a stuck helicopter is left alone. The release point is
 *           CHUTE_LEAD_TIME of flight plus CHUTE_LEAD_EXTRA short of the
 *           point, plus STICK_CENTRE of the stick's length: the middle of
 *           the stick is on the point (Simplex moves its release back by
 *           half the stick the same way)
 *   "drop"  one item out every DROP_INTERVAL (FUNC(releaseItem)), each
 *           accounted delivered (FUNC(account))
 *   "out"   the cart is out: back to the transit height and home to the
 *           module, where it is removed - crew and airframe, its escorts with
 *           it (user, 2026-11-02: virtual until tasked); out of time on the
 *           way, removed where it is
 *
 * RECALLED OR TIMED OUT before the cart is out, what is still aboard is not
 * delivered and it goes out the same way (Simplex's abort turns it for home
 * with the rest aboard). SHOT DOWN, or down on the ground and unable to move
 * (Simplex's commission watch counts that as killed; FUNC(lost)), the same -
 * and the thread closes on the last item either way.
 *
 * Arguments:
 * 0: [logic, aircraft, state, sortie] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(dropTick), 0.25, [_logic, _veh, _st, _sortie]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_logic", "_veh", "_st", "_sortie"];

if (isNull _logic) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_veh] call EFUNC(support_air,sweep);
};

private _catalog = _logic getVariable [QGVAR(catalog), []];
private _queue = _st get "queue";
private _phase = _st get "phase";
private _callsign = _logic getVariable [QGVAR(callsign), DEF_CALLSIGN];

// Whatever is still aboard is not coming.
private _fnc_strand = {
    params ["_why"];
    {
        [_logic, _sortie, (_catalog param [_x, []]) param [ITEM_NAME, "?"], false, _why] call FUNC(account);
    } forEach _queue;
    _queue resize 0;
};
// A flying height for the AI, given again only when it changes.
private _fnc_flyAt = {
    params ["_how"];
    private _z = if (_how isEqualType "") then {[_veh, _how] call EFUNC(support,flightHeight)} else {_how};
    if (abs (_z - (_st getOrDefault ["flyZ", HEIGHT_UNSET])) <= HEIGHT_TOLERANCE) exitWith {};
    _st set ["flyZ", _z];
    [_veh, _z] call EFUNC(support,flyAt);
};
private _fnc_out = {
    _st set ["phase", PHASE_OUT];
    _st set ["until", CBA_missionTime + SORTIE_TIMEOUT];
    _st set ["flyZ", HEIGHT_UNSET];
    _logic setVariable [QGVAR(status), STATUS_LEAVING, true];
    _logic setVariable [QGVAR(plan), [[_st get "exit", PLAN_BASE]], true];
    [FLY_TRANSIT] call _fnc_flyAt;
    [_veh, _st get "exit", "FULL"] call EFUNC(support_air,moveTo);
};

// LOST: shot down, or down on the ground and unable to move.
if (!alive _veh || {isTouchingGround _veh && !canMove _veh}) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    if (alive _veh) then {
        WARNING_3("airdrop: %1 '%2' is down at %3 and cannot move - counted lost, left where it is",_callsign,typeOf _veh,mapGridPosition _veh);
        [_logic, _veh] call FUNC(lost);
    };
    [format ["aircraft lost at %1", mapGridPosition _veh]] call _fnc_strand;
    [_logic, _sortie, _veh] call FUNC(aircraftDone);
};

if (_phase isEqualTo PHASE_OUT) exitWith {
    private _late = CBA_missionTime > (_st get "until");
    if (_veh distance2D (_st get "exit") > HOME_RING && !_late) exitWith {};
    if (_late) then {WARNING_1("%1 did not reach the module in time - removed where it is",_callsign)};
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_logic, _sortie, _veh] call FUNC(aircraftDone);
    [_veh] call EFUNC(support_air,sweep);
};

private _recalled = _logic getVariable [QGVAR(abort), false];
if (_recalled || {CBA_missionTime > (_st get "until")}) exitWith {
    _logic setVariable [QGVAR(abort), false, true];
    private _why = ["timed out", "recalled"] select _recalled;
    INFO_3("airdrop: %1 %2 with %3 still aboard - turning for home",_callsign,_why,count _queue);
    [_why] call _fnc_strand;
    [_logic, _why + " - leaving with what is still aboard", "normal", _sortie get "requester"] call FUNC(say);
    call _fnc_out;
};

private _pos = _sortie get "pos";

if (_phase isEqualTo PHASE_IN) exitWith {
    // INBOUND - ETA and 1 MIN OUT - POP SMOKE (user, 2026-11-01).
    [_logic, _veh, _pos] call FUNC(inbound);
    [[_veh, _st getOrDefault ["height", DEF_DROP_HEIGHT], _veh distance2D _pos] call EFUNC(support,approachHeight)] call _fnc_flyAt;
    // THE RELEASE POINT: the chute's lead, plus half the stick.
    private _ms = speed _veh / KMH_PER_MS;
    private _stick = (count _queue - 1) * DROP_INTERVAL * _ms;
    private _lead = CHUTE_LEAD_TIME * _ms + CHUTE_LEAD_EXTRA + STICK_CENTRE * _stick;
    private _d = _veh distance2D _pos;
    if (_d > _lead) exitWith {};
    _st set ["phase", PHASE_DROP];
    _st set ["next", CBA_missionTime];
    _logic setVariable [QGVAR(status), STATUS_DROPPING, true];
    INFO_6("airdrop: %1 '%2' releases the first of %3 %4 m short of %5 at %6 m/s",_callsign,typeOf _veh,count _queue,round _d,mapGridPosition _pos,round _ms);
    INFO_3("airdrop: %1 is %2 m up - the stick is %3 m long",_callsign,round ((getPosATL _veh) select 2),round _stick);
};

if (CBA_missionTime < (_st get "next")) exitWith {};

private _entry = _catalog param [_queue deleteAt 0, []];
private _item = [_logic, _veh, _entry, _st get "signal"] call FUNC(releaseItem);
if (!isNull _item) then {(_sortie getOrDefault ["items", []]) pushBack _item};
[_logic, _sortie, _entry param [ITEM_NAME, "?"], !isNull _item, "could not be made"] call FUNC(account);
_st set ["next", CBA_missionTime + DROP_INTERVAL];

if (_queue isEqualTo []) then {call _fnc_out};
