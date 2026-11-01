#include "script_component.hpp"
/*
 * Author: JMSB
 * Flips what the player's camera sends on a call: FACE (a camera in front of
 * his face) or VIEW (what he sees). Public on him, so everyone on his call
 * sees the change at their next look (FUNC(callFeedUnit)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * What he sends now, CALL_CAM_FACE or CALL_CAM_VIEW <STRING>
 *
 * Example:
 * [] call jmfsb_tacpad_apps_fnc_callCamFlip
 *
 * Public: No
 */

private _me = call CBA_fnc_currentUnit;
private _send = [CALL_CAM_VIEW, CALL_CAM_FACE] select ((_me getVariable [QGVAR(callCam), CALL_CAM_FACE]) isEqualTo CALL_CAM_VIEW);
_me setVariable [QGVAR(callCam), _send, true];
["CALL", ["Your camera sends your face.", "Your camera sends your view."] select (_send isEqualTo CALL_CAM_VIEW)] call EFUNC(notify,notify);
_send
