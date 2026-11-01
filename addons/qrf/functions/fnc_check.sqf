#include "script_component.hpp"
/*
 * Author: JMSB
 * The capture condition, over every watch: enough players of one side inside,
 * nobody hostile, held continuously. Any break resets the clock - taking
 * ground means clearing it AND staying.
 *
 * Objectives keep being watched after they fall. Losing one and retaking it
 * captures again, which is why the cooldown rather than a one-shot flag is
 * what governs repeat answers.
 *
 * Parameters (CBA PFH): 0: args, 1: handle
 *
 * Public: No
 */

params ["_args", "_handle"];

private _hold = GVAR(holdTime);
private _min = GVAR(minPlayers);

{
    private _w = _x;
    private _pos = _w get "pos";
    private _radius = _w get "radius";

    private _inside = allPlayers select {
        alive _x && {(getPosATL _x) distance2D _pos <= _radius}
    };
    if (_inside isEqualTo []) then {
        _w set ["streak", -1];
        _w set ["held", false];
        continue;
    };

    // Whoever has players inside claims it - one side at a time.
    private _holder = side group (_inside select 0);
    _inside = _inside select {(side group _x) isEqualTo _holder};

    if (count _inside < _min || {[_pos, _radius, _holder] call FUNC(contested)}) then {
        _w set ["streak", -1];
        _w set ["held", false];
        continue;
    };

    private _streak = _w get "streak";
    if (_streak < 0) then { _w set ["streak", CBA_missionTime]; continue };
    if (_w get "held") then { continue };
    if ((CBA_missionTime - _streak) < _hold) then { continue };

    _w set ["held", true];

    if (CBA_missionTime < ((_w get "last") + GVAR(cooldown))) then {
        INFO_1("'%1' taken again, still inside its cooldown - no QRF",_w get "name");
        continue;
    };
    _w set ["last", CBA_missionTime];

    INFO_2("'%1' taken by %2",_w get "name",_holder);
    // Called here, on the server, not raised as a CBA event: any client could
    // raise that one and have a QRF sent at any position (review S7).
    [_w get "name", _holder, +(_w get "pos"), _w get "radius"] call FUNC(onCaptured);
} forEach GVAR(watches);
