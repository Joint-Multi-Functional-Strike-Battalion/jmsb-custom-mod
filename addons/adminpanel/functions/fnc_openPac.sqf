#include "script_component.hpp"
/*
 * Author: JMSB
 * The console's TAC//PAC button. On the vanilla map TAC//PAC opens over the
 * console as it always has, and closing it lands back on the console.
 *
 * ON A TABLET the page is drawn inside the device (jmfsb_pac_fnc_uiOpen), and
 * the console is a dialog laid over the device - so the page would open
 * underneath it. The console closes first and the page opens a frame later,
 * once the device is the top display again; closing TAC//PAC then lands on the
 * tablet.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Asked for <BOOL> - false without the pac addon
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_openPac
 *
 * Public: No
 */

if (isNil "jmfsb_pac_fnc_uiOpen") exitWith {false};

if (HOST_DEVICE && {!isNull (HOST_DISPLAY)}) exitWith {
    (uiNamespace getVariable ["admp_displayVar", displayNull]) closeDisplay 2;
    [{[] call jmfsb_pac_fnc_uiOpen}] call CBA_fnc_execNextFrame;
    true
};

[] call jmfsb_pac_fnc_uiOpen;
true
