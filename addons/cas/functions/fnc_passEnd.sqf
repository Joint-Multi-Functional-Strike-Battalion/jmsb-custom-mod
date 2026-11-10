#include "script_component.hpp"
/*
 * Author: YonV
 * Ends a pass (FUNC(passBegin)) and hands the airframe back to the AI: the
 * dive's frame handler and the Fired handler are removed, the crew's
 * targeting put back as it was, the speed cap lifted, the turret's camera
 * freed, the bays closed, and the AI given its height - no lower than
 * PASS_PULL_OUT_HEIGHT m now, the height it came in at PASS_PULL_OUT_DELAY s
 * later unless a new pass has begun. The dummy laser target stays
 * PASS_DUMMY_LINGER s for rounds still flying. The result is kept for the
 * owner's next FUNC(passTick), which hands it back and forgets the pass -
 * unless the owner ends it itself (a recall, a re-task, the leg home) and
 * says to forget it now. One RPT line. Nothing to do without a pass.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Why, for the RPT <STRING> (optional, default "")
 * 2: The result; "" for "fired" when anything was released, else "aborted" <STRING> (optional, default "")
 * 3: Forget the pass now - no result kept for the owner's watch <BOOL> (optional, default false)
 *
 * Return Value:
 * There was a pass to end <BOOL>
 *
 * Example:
 * [_veh, "recalled", "", true] call jmfsb_cas_fnc_passEnd
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]], ["_why", "", [""]], ["_result", "", [""]], ["_forget", false, [false]]];

private _st = _veh getVariable [QGVAR(pass), createHashMap];
if (count _st isEqualTo 0) exitWith {false};
// Over already, its result waiting: forgotten when asked, else left for the
// owner's watch.
if ((_st get "phase") isEqualTo PASS_DONE) exitWith {
    if (_forget) then {_veh setVariable [QGVAR(pass), nil]};
    false
};

private _pfh = _st get "pfh";
if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler};
_veh removeEventHandler ["Fired", _st get "firedEH"];

private _fired = _st get "fired";
if (_result isEqualTo "") then {_result = [PASS_ABORTED, PASS_FIRED] select (_fired > 0)};
{_st set _x} forEach [["phase", PASS_DONE], ["result", _result], ["pfh", -1], ["ended", CBA_missionTime]];

if (alive _veh) then {
    _veh limitSpeed PASS_NO_SPEED_CAP;
    {
        _x params ["_unit", "_target", "_autoTarget"];
        if (alive _unit) then {
            if (_target) then {_unit enableAI "TARGET"};
            if (_autoTarget) then {_unit enableAI "AUTOTARGET"};
        };
    } forEach (_st get "ai");
    private _turret = _st get "turret";
    if (_turret isNotEqualTo TURRET_PILOT) then {_veh lockCameraTo [objNull, _turret, true]};
    {_veh animateBay [_forEachIndex + 1, 0, false]} forEach (getPylonMagazines _veh);
    // The pull-out: its height back, gently.
    _veh flyInHeight (((getPosATL _veh) select 2) max PASS_PULL_OUT_HEIGHT);
    [{
        params ["_veh", "_began", "_height"];
        if (!alive _veh) exitWith {};
        private _now = (_veh getVariable [QGVAR(pass), createHashMap]) getOrDefault ["began", -1];
        if (_now isEqualTo _began || _now < 0) then {_veh flyInHeight _height};
    }, [_veh, _st get "began", _st get "height"], PASS_PULL_OUT_DELAY] call CBA_fnc_waitAndExecute;
};

[{
    params ["_dummy"];
    if (isNull _dummy) exitWith {};
    detach _dummy;
    deleteVehicle _dummy;
}, [_st get "dummy"], PASS_DUMMY_LINGER] call CBA_fnc_waitAndExecute;

private _dove = if ((_st getOrDefault ["diveAt", -1]) < 0) then {0} else {CBA_missionTime - (_st get "diveAt")};
INFO_7("pass: '%1' %2 - %3 - %4 x %5 released on %6, %7 s in the dive",typeOf _veh,_result,_why,_fired,_st get "mag",mapGridPosition (_st get "aim"),round _dove);
if (_forget) then {_veh setVariable [QGVAR(pass), nil]};
true
