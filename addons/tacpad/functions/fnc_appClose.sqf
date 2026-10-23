#include "script_component.hpp"
/*
 * Author: JMSB
 * Closes whatever app is open on the map, from anywhere.
 *
 * THE ONE TEARDOWN. There used to be several - the frame's own CLOSE, the
 * ground's header-band net, a floating panic button, a FORCE CLOSE strip -
 * each with its own copy of the same four steps and its own way of getting
 * one of them wrong. A page closes the same way whoever asks: the group
 * goes, the marker clears, the panels come back.
 *
 * IT SWEEPS FOR ORPHANS TOO. Deleting only the tracked handle is what let a
 * page get stuck: a group the suite lost its reference to is deleted by
 * nothing and replaced by nothing, so it sits there forever. Every group the
 * suite makes carries QGVAR(owned) - see FUNC(build) - so the display can be
 * swept for our own work and nothing else's, sparing the registered panels
 * because those are not the stuck thing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Something was closed <BOOL>
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_appClose
 *
 * Public: Yes
 */

if (!hasInterface) exitWith {false};

private _was = uiNamespace getVariable [QGVAR(appCurrent), ""];
private _group = uiNamespace getVariable [QGVAR(appGroup), controlNull];
if (_was isEqualTo "" && {isNull _group}) exitWith {false};

if (!isNull _group) then {ctrlDelete _group};
uiNamespace setVariable [QGVAR(appGroup), controlNull];

// Nothing is open now, so every refresh loop stands down on its next tick -
// and no app holds the host's map, so a map click closes again (FUNC(openApp)).
uiNamespace setVariable [QGVAR(appCurrent), ""];
uiNamespace setVariable [QGVAR(appMapClaim), ""];

// And the screen that was open hears it, for whatever it keeps off the group -
// the reader inside the tablet holds the device dialog as its display.
if (_was isNotEqualTo "") then {
    [QGVAR(appClosed), [_was]] call CBA_fnc_localEvent;
};

// The panels come back from their modal hide - see FUNC(openApp).
{
    (_x param [0, controlNull]) ctrlShow true;
} forEach values (missionNamespace getVariable [QGVAR(open), createHashMap]);

// The orphan sweep, a frame later: this is called from inside control
// handlers, and deleting the control that owns the running handler is how
// closing a window takes the closer with it.
[{
    private _map = HOST_DISPLAY;
    if (isNull _map) exitWith {};

    private _panels = (values (missionNamespace getVariable [QGVAR(open), createHashMap]))
        apply {_x param [0, controlNull]};

    {
        if (_x getVariable [QGVAR(owned), false] && {!(_x in _panels)}) then {
            ctrlDelete _x;
        };
    } forEach (allControls _map);
}, []] call CBA_fnc_execNextFrame;

true
