#include "script_component.hpp"
/*
 * Author: JMSB
 * The display the suite draws on right now, or displayNull when there is none.
 *
 * In native mode that is the vanilla map, looked up fresh every time because a
 * display held in a variable is a dead reference the moment the map closes. In
 * tablet mode it is whatever jmfsb_devices handed over through FUNC(setHost) -
 * its dialog while open, displayNull once that dialog has unloaded and cleared
 * it. Either way "is the host open" is `!isNull HOST_DISPLAY`, which is what
 * every refresh loop in the suite asks before it draws.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The host display <DISPLAY>
 *
 * Example:
 * private _display = call jmfsb_tacpad_fnc_hostDisplay
 *
 * Public: Yes
 */

if (HOST_NATIVE) exitWith {findDisplay IDD_MAP};

uiNamespace getVariable [QGVAR(hostDisplay), displayNull]
