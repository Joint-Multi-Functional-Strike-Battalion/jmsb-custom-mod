#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether a press on the map is the running tool's to take.
 *
 * THE MAP IS SHARED WITH THE APPS. On both hosts a press on the map with an app
 * open closes that app (EFUNC(tacpad,appExits)), and an app that picks on the
 * map - TAC//SUPPORT - claims it through EGVAR(tacpad,appMapClaim) while it
 * does. The tools never claim the map and never take a press while an app is
 * open or holds the map: that press is the app's way out or the app's input.
 *
 * The press that closes an app is the awkward one. Both handlers sit on the
 * same control and the engine picks their order, so if the shell's runs first
 * the app is already gone by the time this asks. The frame it closed on is
 * stamped in XEH_postInit and a press on that frame is not a tool's either.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The tool takes this press <BOOL>
 *
 * Example:
 * [] call jmfsb_maptools_fnc_hasInput
 *
 * Public: No
 */

GVAR(tool) isNotEqualTo ""
&& {(uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isEqualTo ""}
&& {(uiNamespace getVariable [QEGVAR(tacpad,appMapClaim), ""]) isEqualTo ""}
&& {GVAR(closedFrame) != diag_frameNo}
