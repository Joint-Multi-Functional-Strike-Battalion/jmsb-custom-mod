#include "script_component.hpp"
/*
 * Author: YonV
 * The LOG app (user, 2026-11-09: "we also need to add back in the logs app"):
 * the notices log - every notification that scrolled past - as an app of its
 * own in the MENU and on a live tile, not only behind SETTINGS > NETS &
 * ALERTS, the MSG tile's long press and the notification line. It is the
 * docked reader's LOG view (FUNC(openLog), FUNC(panelReader)), so opening it
 * here hands over to that, the next frame - FUNC(openLog) closes the open app,
 * and this is being opened as one.
 *
 * Arguments:
 * 0: The host display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_tacpad_apps_fnc_appLog
 *
 * Public: No
 */

{[] call FUNC(openLog)} call CBA_fnc_execNextFrame;
