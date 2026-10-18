#include "script_component.hpp"
/*
 * Author: JMSB
 * How much of a target the player can see, 0 to 1. NO SEEING THROUGH WALLS:
 * a target hidden from every point checked is 0 and is not drawn; vegetation
 * in the VIEW LOD is part-transparent, so a man in a bush comes back as a
 * fraction and is drawn faded.
 *
 * Several points per target and the best one wins, so a man whose head is over
 * a wall is seen even though his pelvis is behind it.
 *
 * Arguments:
 * 0: Target - a man or a vehicle <OBJECT>
 *
 * Return Value:
 * Visibility, 0..1 <NUMBER>
 *
 * Example:
 * [cursorObject] call jmfsb_ecoti_fnc_targetVisibility
 *
 * Public: No
 */

params [["_target", objNull, [objNull]]];

if (isNull _target) exitWith {0};

private _eye = eyePos player;
// A man: his eyes, his chest, and halfway from his chest to the ground - his
// hips, without needing his skeleton.
private _points = if (_target isKindOf "CAManBase") then {
    private _chest = aimPos _target;
    [eyePos _target, _chest, (_chest vectorAdd (getPosASLVisual _target)) vectorMultiply 0.5]
} else {
    [aimPos _target, _target modelToWorldVisualWorld ORIGIN]
};

// The player's own vehicle and the target itself are ignored - neither should
// hide the target from the sensor.
private _ignore = vehicle player;
private _best = 0;
{
    _best = _best max ([_ignore, VIS_LOD, _target] checkVisibility [_eye, _x]);
} forEach _points;

_best
