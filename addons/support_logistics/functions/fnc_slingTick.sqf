#include "script_component.hpp"
/*
 * Author: YonV
 * The watch on one SLING helicopter and the item on its hook, every
 * AIR_TICK seconds - one watch per helicopter of the order. The set-down is
 * on Simplex Support Services' method (2026-11-05; the load is put on the
 * ground and let go there, by a scripted hover, not the AI; no code of it
 * used), flown by support_air's flight control (EFUNC(support_air,heliTake)):
 *
 *   "in"     carrying the load nap of the earth with the rope and the load
 *            added under it - the support core's sling height, given to the
 *            AI once and again only when it changes (the shared controller
 *            climbs a stuck helicopter; a watch that set the height back
 *            every tick undid that). SLING_APPROACH out the control takes
 *            the airframe to a hover with the load the module's Unload
 *            Height over the point's surface, clear of what is round it
 *   "hover"  there (SLING_HOVER_RING, SLING_HOVER_BAND): taken again, down
 *            to a hover with the load resting on the ground
 *   "lower"  the load's underside within SLING_SET_DOWN of the surface, or
 *            touching it: the hook is let go, the item marked
 *            (FUNC(markItem)) and accounted delivered (FUNC(account)). Not
 *            down SLING_PATIENCE s after the take: let go where it hangs,
 *            its landing watched (EFUNC(common,ensureSafeLanding)), said in
 *            the RPT
 *   "out"    home to the module nap of the earth - the order takes the
 *            airframe off the control - and removed there: crew, airframe,
 *            whatever is still on the hook, its escorts with it (user,
 *            2026-11-02: virtual until tasked); out of time on the way,
 *            removed where it is
 *
 * Every helicopter that unloaded or went down is one item accounted for;
 * the delivery ends when the last of them is gone (FUNC(aircraftDone)).
 *
 * RECALLED OR TIMED OUT with the load still on, it is carried home on the
 * hook and removed with the airframe (Simplex's abort flies it back the
 * same way; a load deleted in mid-air vanished in front of the section)
 * and is not delivered. A load that fell off on the way, or a helicopter
 * shot down with it, is not delivered either. A helicopter down on the
 * ground and unable to move is lost as much as one shot down (Simplex's
 * commission watch counts it so): FUNC(lost), its load not delivered.
 *
 * Arguments:
 * 0: [logic, helicopter, state, sortie] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(slingTick), 1, [_logic, _veh, _st, _sortie]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_logic", "_veh", "_st", "_sortie"];

// The airframe and whatever is still on its hook go together.
private _fnc_remove = {
    private _hooked = getSlingLoad _veh;
    if (!isNull _hooked) then {
        INFO_2("sling: '%1' removed with '%2' still on the hook",typeOf _veh,typeOf _hooked);
        deleteVehicle _hooked;
    };
    [_veh] call EFUNC(support_air,sweep);
};

if (isNull _logic) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    call _fnc_remove;
};

private _phase = _st get "phase";
private _item = _st get "item";
private _name = _st get "name";
private _callsign = _logic getVariable [QGVAR(callsign), DEF_CALLSIGN];

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
    // With a load still hooked (a recall) the support core adds the rope
    // and the load to the height.
    [FLY_TRANSIT] call _fnc_flyAt;
    [_veh, _st get "exit", "FULL"] call EFUNC(support_air,moveTo);
    if (((_sortie get "aircraft") - [_veh]) findIf {alive _x} < 0) then {
        _logic setVariable [QGVAR(status), STATUS_LEAVING, true];
        _logic setVariable [QGVAR(plan), [[_st get "exit", PLAN_BASE]], true];
    };
};

// LOST: shot down, or down on the ground and unable to move.
if (!alive _veh || {isTouchingGround _veh && !canMove _veh}) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    if (alive _veh) then {
        WARNING_3("sling: %1 '%2' is down at %3 and cannot move - counted lost, left where it is",_callsign,typeOf _veh,mapGridPosition _veh);
        [_logic, _veh] call FUNC(lost);
    };
    if (_phase isNotEqualTo PHASE_OUT) then {
        [_logic, _sortie, _name, false, format ["aircraft lost at %1", mapGridPosition _veh]] call FUNC(account);
    };
    [_logic, _sortie, _veh] call FUNC(aircraftDone);
};

if (_phase isEqualTo PHASE_OUT) exitWith {
    private _late = CBA_missionTime > (_st get "until");
    if (_veh distance2D (_st get "exit") > HOME_RING && !_late) exitWith {};
    if (_late) then {WARNING_1("%1 did not reach the module in time - removed where it is",_callsign)};
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_logic, _sortie, _veh] call FUNC(aircraftDone);
    call _fnc_remove;
};

private _recalled = _logic getVariable [QGVAR(abort), false];
if (_recalled || {CBA_missionTime > (_st get "until")}) exitWith {
    private _why = ["timed out", "recalled"] select _recalled;
    [_logic, _sortie, _name, false, _why] call FUNC(account);
    // Every helicopter of the order hears the recall; the last one clears it.
    if (((_sortie get "aircraft") - [_veh]) findIf {alive _x && {_x getVariable [QGVAR(loaded), true]}} < 0) then {
        _logic setVariable [QGVAR(abort), false, true];
    };
    _veh setVariable [QGVAR(loaded), false];
    INFO_3("sling: %1 %2 - '%3' carried home on the hook, not delivered",_callsign,_why,_name);
    [_logic, format ["%1 - %2 not delivered", _why, _name], "normal", _sortie get "requester"] call FUNC(say);
    call _fnc_out;
};

if (isNull _item || {isNull getSlingLoad _veh}) exitWith {
    WARNING_3("sling: %1 lost '%2' off the hook at %3",_callsign,_name,mapGridPosition _veh);
    [_logic, _sortie, _name, false, "the load was lost on the way"] call FUNC(account);
    _veh setVariable [QGVAR(loaded), false];
    call _fnc_out;
};

private _pos = _st get "pos";
private _d = _veh distance2D _pos;
private _unload = _logic getVariable [QGVAR(unloadHeight), DEF_UNLOAD_HEIGHT];

if (_phase isEqualTo PHASE_IN) exitWith {
    // INBOUND - ETA and 1 MIN OUT - POP SMOKE, the lead helicopter (user,
    // 2026-11-01).
    [_logic, _veh, _pos] call FUNC(inbound);
    if (_d > SLING_APPROACH) exitWith {[FLY_TRANSIT] call _fnc_flyAt};

    // THE TAKE. The hang is the rope plus the load, read now that both exist;
    // the point's surface is the highest thing from SURFACE_SCAN_UP above the
    // terrain down, the load looked past - the control scans it the same way.
    private _rope = 0;
    {_rope = _rope max (ropeLength _x)} forEach (ropes _veh);
    if (_rope <= 0) then {_rope = SLING_HANG};
    (boundingBoxReal _item) params ["_low", "_high"];
    private _hang = _rope + ((_high select 2) - (_low select 2));
    _pos params ["_px", "_py"];
    private _terrain = (getTerrainHeightASL [_px, _py]) max SEA_LEVEL;
    private _hits = lineIntersectsSurfaces [[_px, _py, _terrain + SURFACE_SCAN_UP], [_px, _py, _terrain - SURFACE_SCAN_DOWN], _veh, _item, true, 1, "GEOM", "FIRE"];
    private _surface = if (_hits isEqualTo []) then {_terrain} else {((_hits select 0) select 0) select 2};

    _st set ["hang", _hang];
    _st set ["surface", _surface];
    _st set ["low", _low select 2];
    _st set ["since", CBA_missionTime];
    _st set ["phase", PHASE_HOVER];
    _logic setVariable [QGVAR(status), STATUS_SETTING, true];
    private _taken = [_veh, _pos, _hang + _unload, false, true, SLING_APPROACH_SPEED, "the unload hover", _item, _hang] call EFUNC(support_air,heliTake);
    INFO_6("sling: %1 '%2' %3 m from %4 - to a hover with '%5' %6 m over the point, then lowered to the ground",_callsign,typeOf _veh,round _d,mapGridPosition _pos,_name,_unload);
    if (!_taken) then {
        WARNING_3("sling: the flight control would not take '%1' - '%2' is let go where it hangs after %3 s",typeOf _veh,_name,SLING_PATIENCE);
    };
};

private _hang = _st get "hang";
private _surface = _st get "surface";
private _held = CBA_missionTime - (_st get "since");
private _patience = _held > SLING_PATIENCE;

// HOVER: with the load the Unload Height over the point - then down.
if (_phase isEqualTo PHASE_HOVER && !_patience) exitWith {
    private _over = ((getPosASL _veh) select 2) - _surface;
    if (_d > SLING_HOVER_RING || abs (_over - (_hang + _unload)) > SLING_HOVER_BAND) exitWith {};
    _st set ["phase", PHASE_LOWER];
    [_veh, _pos, _hang, false, true, SLING_APPROACH_SPEED, "the set-down", _item] call EFUNC(support_air,heliTake);
    INFO_4("sling: %1 in the hover at %2 after %3 s - lowering '%4' to the ground",_callsign,mapGridPosition _veh,round _held,_name);
};

// LOWER: the hook let go once the load rests on the ground - or, out of
// patience, where it hangs.
private _bottom = ((getPosASL _item) select 2) + (_st get "low") - _surface;
private _rests = isTouchingGround _item || _bottom < SLING_SET_DOWN;
if (!_rests && !_patience) exitWith {};
_veh setSlingLoad objNull;
if (_rests) then {
    INFO_4("sling: %1 sets '%2' down at %3, %4 s after the take - hook let go",_callsign,_name,mapGridPosition _item,round _held);
} else {
    WARNING_4("sling: %1 could not settle '%2' in %3 s - let go %4 m up",_callsign,_name,SLING_PATIENCE,round _bottom);
    [_item] call EFUNC(common,ensureSafeLanding);
};
[_item, _st get "signal"] call FUNC(markItem);
_veh setVariable [QGVAR(loaded), false];
(_sortie getOrDefault ["items", []]) pushBack _item;
[_logic, _sortie, _name, true, ""] call FUNC(account);
call _fnc_out;
