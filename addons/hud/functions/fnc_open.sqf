#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the layer up, if it is not already.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

if (!hasInterface || {!GVAR(enabled)}) exitWith {};
// In tablet mode the device carries these readouts; the HUD is a second copy
// unless the player asked for it - see the showInTablet setting.
if (HOST_DEVICE && {!GVAR(showInTablet)}) exitWith {};
if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};

// NOT OUTSIDE A MISSION. CBA settings initialise in the MAIN MENU as well
// as in a mission, and both of this addon's openers hang off settings
// (CBA_settingsInitialized, and the enabled setting's own changed handler),
// so reaching the menu used to raise the HUD there.
//
// A HUD belongs to a man in a world. With no player there is nothing to
// report on and nothing to report to.
//
// IT WAITS RATHER THAN GIVING UP, because a refusal that never retries is
// a mission with no HUD at all - and that is exactly what happened when the
// slots moved onto the mission display: CBA_settingsInitialized fires while
// the mission is still coming up, display 46 did not exist yet, and this
// gave up for good. The HUD never got built and Shift + [ did nothing,
// because the keybinds only redraw - they do not raise it.
//
// BOTH CONDITIONS, because either one missing means there is nothing to
// build or nothing to build it on. Whoever asked first is the only one who
// waits - the guard on the stored display above stops a queue forming.
if (isNull player || {isNull (findDisplay 46)}) exitWith {
    if (uiNamespace getVariable [QGVAR(waitingForPlayer), false]) exitWith {};
    uiNamespace setVariable [QGVAR(waitingForPlayer), true];

    [
        {!isNull player && {!isNull (findDisplay 46)}},
        {
            uiNamespace setVariable [QGVAR(waitingForPlayer), false];
            [] call FUNC(open);
            [] call FUNC(draw);
        },
        [],
        // No mission is coming: in the main menu this simply expires, and
        // the flag is cleared so the next mission can wait again. If a slow
        // load outruns it the HUD is not lost either - FUNC(draw) raises it
        // on the next tick.
        60,
        {uiNamespace setVariable [QGVAR(waitingForPlayer), false]}
    ] call CBA_fnc_waitUntilAndExecute;
};

// ON THE MISSION DISPLAY, NOT A TITLE LAYER - see the note at the top of
// gui.hpp. Display 46 is created with the mission and destroyed with it by
// the engine, so the HUD cannot survive onto the main menu by any route.
// This replaced eight builds of menu-side teardown that could not reach a
// title layer from outside the mission that raised it.
private _display = findDisplay 46;

_display ctrlCreate [QGVAR(slotLeft), IDC_HUD_LEFT];
_display ctrlCreate [QGVAR(slotRight), IDC_HUD_RIGHT];

GVAR(raisedAt) = CBA_missionTime;
uiNamespace setVariable [QGVAR(display), _display];

// A CONTROL IS BORN VISIBLE, so the show/hide cache is told that rather than
// carrying an answer about the slots of a previous mission. FUNC(setShown) only
// acts when its answer turns over; left stale across a rebuild it would decide
// there was nothing to do and leave a fresh HUD sitting over whatever screen
// was open at the time.
uiNamespace setVariable [QGVAR(shown), true];

// NOTHING IS DRAWN HERE. Every caller draws straight after, and FUNC(draw)
// calls back into this to raise the HUD when it finds no display - so a
// draw from here would be a loop.
