#include "script_component.hpp"
/*
 * Author: YonV
 * Turns the live tiles' page by a step - the device arrows' job on the
 * tablet (user, 2026-10-31: "the arrows on the tablet should move the live
 * tiles"; jmfsb_devices_fnc_softKey). The band is drawn again next frame
 * into the body it last drew in, with the arguments it last had
 * (FUNC(panelTiles) keeps both). Answers false when there is nothing to
 * turn - no band drawn, or one page - so the caller can do its next thing;
 * true at the end of the pages too, since the key was the band's.
 *
 * Arguments:
 * 0: Step: -1 back, 1 on <NUMBER>
 *
 * Return Value:
 * Taken by the band <BOOL>
 *
 * Example:
 * [1] call jmfsb_tacpad_apps_fnc_tilePageStep
 *
 * Public: No
 */

params [["_step", 0, [0]]];

private _args = uiNamespace getVariable [QGVAR(tileArgs), []];
if (_args isEqualTo [] || {isNull (_args select 0)}) exitWith {false};
private _pages = uiNamespace getVariable [QGVAR(tilePages), 1];
if (_pages <= 1) exitWith {false};

private _was = uiNamespace getVariable [QGVAR(tilePage), 0];
private _page = (_was + _step) max 0 min (_pages - 1);
if (_page isEqualTo _was) exitWith {true};
uiNamespace setVariable [QGVAR(tilePage), _page];
[FUNC(panelTiles), _args] call CBA_fnc_execNextFrame;
true
