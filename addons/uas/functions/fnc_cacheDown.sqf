#include "script_component.hpp"
/*
 * Author: YonV
 * A cache died: that side's ceiling drops to the reduced number for a random
 * window.
 *
 * Windows EXTEND rather than stack - a second kill while the first outage
 * runs pushes the end out if its own window is longer, but two kills can
 * never multiply into a permanent grounding. The sky is supposed to come
 * back; that is what makes hitting supply a raid rather than a win button.
 *
 * Arguments:
 * 0: The cache <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_cache", objNull, [objNull]]];

private _side = _cache getVariable [QGVAR(cacheSide), sideUnknown];
if (_side isEqualTo sideUnknown) exitWith {};

private _lo = GVAR(windowMin);
private _hi = GVAR(windowMax) max _lo;
private _window = _lo + random (_hi - _lo);
private _until = (CBA_missionTime + _window) max (GVAR(outages) getOrDefault [str _side, -1]);

GVAR(outages) set [str _side, _until];

INFO_2("cache killed: %1 patrols thinned for %2s",_side,round _window);
["SUPPLY", format ["%1 drone supply hit - their air thins out for a while.", _side]]
    call EFUNC(notify,broadcast);

// THE ENEMY REBUILDS, IF THERE IS A COMMANDER TO SEND ANYONE. A hit cache is a
// place the commander now knows is reachable; LOGCOM sends a section to hold the
// ground, by convoy - one the players can interdict, and can find, since LOCATE
// LOGISTICS points at where it starts. Soft-linked like every adapter call.
//
// Without ALiVE there is no logistics model and nothing is coming: the ceiling
// drops for the outage window and comes back when the window closes rather than
// when a convoy arrives. Both endings are correct; which one you get is whether
// a commander exists to be told.
if (!isNil QEFUNC(adapter_alive,requestSupply)) then {
    [_side, getPosATL _cache, [1, 0, 0, 0, 0, 0]] call EFUNC(adapter_alive,requestSupply);
};
