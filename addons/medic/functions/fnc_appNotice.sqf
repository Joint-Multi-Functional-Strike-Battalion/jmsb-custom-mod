#include "script_component.hpp"
/*
 * Author: JMSB
 * The page the app shows when there is nothing to triage with: a headline in
 * the accent and one line under it saying why.
 *
 * Arguments:
 * 0: Body to fill <CONTROL>
 * 1: Headline <STRING>
 * 2: Explanation <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, "MEDICAL SYSTEM NOT LOADED", "ACE MEDICAL IS NOT RUNNING"] call jmfsb_medic_fnc_appNotice
 *
 * Public: No
 */

// Where the headline sits, as a fraction of the body's height.
#define NOTICE_Y 0.38
#define NOTICE_SIZE TEXT_DISPLAY
#define NOTICE_LINE_SIZE TEXT_BODY
#define NOTICE_GAP 0.4

params [["_body", controlNull, [controlNull]], ["_title", "", [""]], ["_line", "", [""]]];

if (isNull _body) exitWith {};

(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = PAD * HOST_W;
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _y = _h * NOTICE_Y;

[_body, [_pad, _y, _w - 2 * _pad, _rowH * NOTICE_SIZE], _title, ["accent"] call EFUNC(tacpad,theme), NOTICE_SIZE, true, "center", true] call EFUNC(tacpad,drawText);
[_body, [_pad, _y + _rowH * (NOTICE_SIZE + NOTICE_GAP), _w - 2 * _pad, _rowH], _line, ["muted"] call EFUNC(tacpad,theme), NOTICE_LINE_SIZE, false, "center"] call EFUNC(tacpad,drawText);
