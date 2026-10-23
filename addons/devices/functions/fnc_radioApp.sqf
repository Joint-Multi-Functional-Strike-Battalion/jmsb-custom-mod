#include "script_component.hpp"
/*
 * Author: JMSB
 * Opens or closes the RADIO app full screen on the carried phone or side device
 * (docs/DESIGN_VOICE.md, "Phone and side RADIO app"; numpad 6 by default).
 *
 * It is drawn on the walking view itself (FUNC(radioDraw)), over the map, the
 * squad list and the net row, so the player keeps walking while he works it:
 * numpad 0 / . move the cursor, the device keys F1-F4 are its soft keys,
 * numpad 7 / 8 step its tabs. It opens on CALLS while a call is live or
 * ringing, on NETS otherwise. Only while the walking view is up; the voice
 * addon must be loaded.
 *
 * Arguments:
 * 0: Open - true, false, or nil to toggle <BOOL> (optional)
 *
 * Return Value:
 * Now open <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_radioApp
 *
 * Public: No
 */

params [["_open", nil, [true]]];

if (isNil "_open") then {_open = !GVAR(radioOpen)};
if (_open && {isNull (uiNamespace getVariable [QGVAR(overlayDisplay), displayNull]) || {isNil QEFUNC(voice,netState)}}) exitWith {false};

GVAR(radioOpen) = _open;
GVAR(radioCursor) = 0;
GVAR(radioGroupMode) = false;
GVAR(quickOpen) = false;

if (_open) then {
    private _busy = !isNil QEFUNC(voice,calls) && {(([] call EFUNC(voice,calls)) findIf {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING, CALL_RINGING]}) >= 0};
    GVAR(radioTab) = ["nets", "calls"] select _busy;
};

[] call FUNC(overlayTick);
_open
