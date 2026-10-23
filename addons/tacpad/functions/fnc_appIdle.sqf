#include "script_component.hpp"
/*
 * Author: JMSB
 * Is it safe to redraw the open app right now?
 *
 * THIS IS THE ANSWER TO "THE APP PAGES WILL NOT TAKE A CLICK". A live app keeps
 * up with its subject by REOPENING itself on a timer, and opening an app deletes
 * the previous group and builds a new one - see FUNC(appFrame). So a screen with
 * a one-second loop was destroying and recreating every button on it once a
 * second, and a control deleted between the press and the release NEVER raises a
 * click. Pressing anything on INTRUSION, TIMER or the scanner was a coin toss,
 * and a slow press lost every time.
 *
 * Fixing the loops' variable names is what re-enabled that: while they were
 * reading a name nothing wrote, they removed themselves on their first tick and
 * the screens were merely frozen rather than hostile.
 *
 * THE POINTER IS THE TELL. Inside the app the player is aiming at something, so
 * the redraw waits; outside it they are looking, so it goes ahead. A screen
 * therefore updates while it is being read and holds still while it is being
 * used, which is the behaviour a player would describe as "it works".
 *
 * IT IS A HOLD, NOT A STOP, AND THAT DISTINCTION WAS THE BUG. A player watching
 * a progress bar rests the cursor on the window - so the pointer test was true
 * for as long as they were looking at it, the screen never redrew, and the
 * intrusion bar sat at 0% for the whole hack. The hack itself was running
 * perfectly; the screen was a photograph of its first frame.
 *
 * So the hold expires. Three seconds without a redraw and one goes through
 * regardless of where the cursor is: a bar that steps every three seconds is a
 * bar, and a press has to be very unlucky to land in that one frame.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Safe to redraw <BOOL>
 *
 * Example:
 * if !([] call jmfsb_tacpad_fnc_appIdle) exitWith {}
 *
 * Public: Yes
 */

private _group = uiNamespace getVariable [QGVAR(appGroup), controlNull];
if (isNull _group) exitWith {false};

getMousePosition params [["_mx", -1], ["_my", -1]];
(ctrlPosition _group) params ["_x", "_y", "_w", "_h"];

// NEVER REBUILD UNDER THE TITLE BAR. The 3-second expiry below exists for a
// man watching a progress bar with his cursor parked on the BODY; a cursor on
// the header is a finger over CLOSE, and a rebuild deleting that button under
// the press is "the window will not close" - reported on three apps, all of
// them the ones with refresh loops.
private _headerH = (HEADER_H * GVAR(textScale) * GVAR(uiScale) * HOST_H) max ([TEXT_TITLE] call FUNC(textH));
if (_mx >= _x && {_mx <= _x + _w} && _my >= _y && {_my <= _y + _headerH + RULE_THICK * pixelH * 2}) exitWith {false};

// Held too long already - see above. FUNC(openApp) stamps this every time it
// actually draws.
if ((diag_tickTime - (uiNamespace getVariable [QGVAR(appDrawn), 0])) > 3) exitWith {true};

!(_mx >= _x && {_mx <= _x + _w} && _my >= _y && {_my <= _y + _h})
