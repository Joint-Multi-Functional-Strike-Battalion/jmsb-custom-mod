#include "script_component.hpp"
/*
 * Author: JMSB
 * Should this app's refresh loop keep running?
 *
 * An app group existing is not the same as THIS app being open - opening a
 * second screen replaces the first, and the first's loop would otherwise carry
 * on rebuilding its own over the top of it.
 *
 * Arguments:
 * 0: App id <STRING>
 *
 * Return Value:
 * Keep going <BOOL>
 *
 * Example:
 * if !(["hack"] call jmfsb_tacpad_fnc_appAlive) exitWith {}
 *
 * Public: Yes
 */

params [["_app", "", [""]]];

!isNull (uiNamespace getVariable [QGVAR(appGroup), controlNull])
&& {!isNull (HOST_DISPLAY)}
&& {(uiNamespace getVariable [QGVAR(appCurrent), ""]) isEqualTo _app}
