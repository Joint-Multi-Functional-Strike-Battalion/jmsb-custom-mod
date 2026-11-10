#include "script_component.hpp"
/*
 * Author: YonV
 * Makes a control clickable.
 *
 * CONTROLS ON THE MAP DISPLAY DO TAKE INPUT. An earlier build was written
 * against the opposite belief - that display 12 gives every click to the map at
 * IDC 51 - and so registered rectangles here and hit-tested them from a
 * dispatcher on the map control. That deadlocked: the transparent RscButton laid
 * over each row consumed the click, which is what a button does, so neither the
 * map control nor the display ever saw the event and the dispatcher never ran.
 * Nothing in the suite could be pressed.
 *
 * What is actually true is narrower: RscText and RscStructuredText raise no
 * ButtonClick, so the text a panel draws cannot be the thing that is pressed.
 * That is why a hotspot is a real RscButton laid over the text - and why the
 * handler belongs on it and nowhere else. BCE declares a whole toolbar of
 * buttons into RscDisplayMainMap and drives them with onButtonClick; this is the
 * same thing, built at runtime.
 *
 * A structured text label lying over a button still takes the press away from
 * it, though, which is the other half of the story - see FUNC(drawHit).
 *
 * A CLICK IS A BUTTON, because ButtonClick is the engine's own
 * press-in-release-in rule - which is what an earlier dispatcher was hand-rolling
 * with a remembered press and a second hit test.
 *
 * Panels do not move, so a hotspot is the only kind there is - see
 * FUNC(build).
 *
 * Arguments:
 * 0: Hotspot control - an RscButton (QGVAR(hit)) <CONTROL>
 * 1: Called with [control] when clicked <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_hit, {["comms"] call jmfsb_tacpad_fnc_openApp}] call jmfsb_tacpad_fnc_hotspot
 *
 * Public: Yes
 */

params [["_ctrl", controlNull, [controlNull]], ["_handler", {}, [{}]]];

if (isNull _ctrl) exitWith {};

// It hands the handler [control], which is the signature every caller has.
_ctrl ctrlAddEventHandler ["ButtonClick", _handler];
