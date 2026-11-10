#include "script_component.hpp"
/*
 * Author: YonV
 * Registers a full-size app, which is what a live tile opens. Kept separate
 * from FUNC(register) because a panel and an app are different things: a panel
 * is always on the map screen if the player wants it, an app is opened over the
 * map and closed again.
 *
 * Arguments:
 * 0: App id <STRING>
 * 1: Handler, called with [display, appId, args] <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["squad", FUNC(appSquad)] call jmfsb_tacpad_fnc_registerApp
 *
 * Public: Yes
 */

params [["_app", "", [""]], ["_handler", {}, [{}]]];

if (_app == "" || {_handler isEqualTo {}}) exitWith {};

GVAR(appHandlers) set [_app, _handler];
