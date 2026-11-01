#include "script_component.hpp"
/*
 * Author: JMSB
 * The call's picture: a camera on the other man on the player's live call
 * (FUNC(callFeedUnit)), rendered to a texture (CALL_FEED_RTT) that the call
 * window floating over the tablet and the walking view shows
 * (jmfsb_devices_fnc_callWindow, jmfsb_devices_fnc_overlayCallFeed). One feed
 * per machine. No video is sent: each viewer's machine renders the scene itself,
 * from where the shown man's head is and where he looks. What his camera sends
 * is his choice (FUNC(callCamFlip)): FACE - in front of his face, looking back
 * at him - or VIEW - at his eyes, looking where he looks.
 *
 *   "show"  starts the feed, or keeps it, with the screen's alive test
 *   "stop"  ends the render and deletes the camera
 *
 * IT CLEANS UP AFTER ITSELF. A per-frame handler moves the camera with the
 * shown man's head, looks again at who is shown and what he sends every
 * CALL_FEED_TICK, and stops the feed the moment the screen's alive test
 * fails or there is no live call. A render surface left running is a second
 * scene drawn every frame for nobody.
 *
 * Arguments:
 * 0: Mode - "show" or "stop" <STRING>
 * 1: Alive test - true while the screen showing the feed is up <CODE>
 *    (optional, default {false})
 *
 * Return Value:
 * None
 *
 * Example:
 * ["show", {!isNull (uiNamespace getVariable ["jmfsb_devices_display", displayNull])}] call jmfsb_tacpad_apps_fnc_callFeed
 *
 * Public: No
 */

params [["_mode", "stop", [""]], ["_alive", {false}, [{}]]];

private _fnc_stop = {
    private _cam = uiNamespace getVariable [QGVAR(callFeedCam), objNull];
    if (!isNull _cam) then {
        _cam cameraEffect ["Terminate", "Back", CALL_FEED_RTT];
        camDestroy _cam;
    };
    private _pfh = uiNamespace getVariable [QGVAR(callFeedPFH), -1];
    if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler};
    uiNamespace setVariable [QGVAR(callFeedCam), objNull];
    uiNamespace setVariable [QGVAR(callFeedPFH), -1];
    uiNamespace setVariable [QGVAR(callFeedShown), []];
};

if (_mode isNotEqualTo "show") exitWith {call _fnc_stop};

// The latest screen to ask owns the feed's alive test.
uiNamespace setVariable [QGVAR(callFeedAlive), _alive];
if (!isNull (uiNamespace getVariable [QGVAR(callFeedCam), objNull])) exitWith {};

private _cam = "camera" camCreate [0, 0, 0];
_cam cameraEffect ["Internal", "Back", CALL_FEED_RTT];
CALL_FEED_RTT setPiPEffect [0];
uiNamespace setVariable [QGVAR(callFeedCam), _cam];
uiNamespace setVariable [QGVAR(callFeedShown), []];

uiNamespace setVariable [QGVAR(callFeedPFH), [{
    params ["_args"];
    _args params ["_cam", "_fnc_stop"];

    if (isNull _cam || {!(call (uiNamespace getVariable [QGVAR(callFeedAlive), {false}]))}) exitWith {call _fnc_stop};

    // Who is shown, his camera and the caption: looked at again every tick,
    // not every frame.
    if (diag_tickTime >= (_cam getVariable [QGVAR(feedNext), 0])) then {
        _cam setVariable [QGVAR(feedNext), diag_tickTime + CALL_FEED_TICK];
        private _shown = [] call FUNC(callFeedUnit);
        uiNamespace setVariable [QGVAR(callFeedShown), _shown];
        if (_shown isEqualTo []) exitWith {};
        _cam camSetFov ([CALL_CAM_FACE_FOV, CALL_CAM_VIEW_FOV] select ((_shown select 1) isEqualTo CALL_CAM_VIEW));
        _cam camCommit 0;
    };

    (uiNamespace getVariable [QGVAR(callFeedShown), []]) params [["_unit", objNull, [objNull]], ["_send", CALL_CAM_FACE, [""]]];
    if ((uiNamespace getVariable [QGVAR(callFeedShown), []]) isEqualTo []) exitWith {call _fnc_stop};
    if (isNull _unit) exitWith {};

    // FACE: out in front of his eyes, turned back on him. VIEW: at his eyes,
    // a little ahead so his own head is not in the shot. Both distances are
    // this player's settings (GVAR(callFaceDist), GVAR(callViewAhead)).
    private _eye = eyePos _unit;
    private _dir = eyeDirection _unit;
    if (_send isEqualTo CALL_CAM_VIEW) then {
        _cam setPosASL (_eye vectorAdd (_dir vectorMultiply GVAR(callViewAhead)));
    } else {
        _cam setPosASL (_eye vectorAdd (_dir vectorMultiply GVAR(callFaceDist)));
        _dir = _dir vectorMultiply -1;
    };
    _cam setVectorDirAndUp [_dir, _dir vectorCrossProduct [-(_dir select 1), _dir select 0, 0]];
}, 0, [_cam, _fnc_stop]] call CBA_fnc_addPerFrameHandler];
