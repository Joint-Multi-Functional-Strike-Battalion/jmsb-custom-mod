#include "script_component.hpp"
/*
 * Author: JMSB
 * The custom nets the voice server publishes (jmfsb_voice_fnc_customList;
 * user, 2026-10-22: "allow rtos to add custom channels"), as the RADIO board
 * reads them - once for the MANAGE tab and once for the redraw key. A voice
 * addon without the call answers none, so the board still draws.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[id, name, squads (upper-case callsigns), uids, ownerUid, ownerName], ...] <ARRAY>
 *
 * Example:
 * private _custom = [] call jmfsb_tacpad_apps_fnc_radioCustom
 *
 * Public: No
 */

if (isNil QEFUNC(voice,customList)) exitWith {[]};

([] call EFUNC(voice,customList)) select {_x isEqualType [] && {(_x param [0, ""]) isEqualType ""}}
