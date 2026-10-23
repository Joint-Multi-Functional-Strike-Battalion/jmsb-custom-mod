#include "script_component.hpp"
/*
 * Author: JMSB
 * The FEED's picture: a camera on the picked drone's gunner optic, rendered to
 * a texture (DRONES_FEED_RTT) that the FEED panel's picture shows inside the
 * app. One feed per machine. While the drone lases, the HUD's target line is
 * the lased grid.
 *
 *   "show"  points the feed at a drone (the camera is kept when it is the same
 *           drone - a redraw rebuilds the picture, not the camera) and takes
 *           the HUD lines to keep current
 *   "stop"  ends the render and deletes the camera
 *
 * IT CLEANS UP AFTER ITSELF. A per-frame handler steers the camera with the
 * optic and rewrites the HUD every DRONES_HUD_TICK, and stops the feed the
 * moment the app is closed or replaced (EFUNC(tacpad,appAlive)), the page or
 * the pick changes, or the drone is gone. A render surface left running is a
 * second scene drawn every frame for nobody.
 *
 * Arguments:
 * 0: Mode - "show" or "stop" <STRING>
 * 1: Drone <OBJECT> (optional, default objNull)
 * 2: HUD lines [[control, id, size, align], ...]; id is "id", "nav", "tgt" or
 *    "link" <ARRAY> (optional, default [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["show", _uav, _hud] call jmfsb_tacpad_apps_fnc_appDronesCamera
 *
 * Public: No
 */

params [["_mode", "stop", [""]], ["_uav", objNull, [objNull]], ["_hud", [], [[]]]];

private _fnc_stop = {
    private _cam = uiNamespace getVariable [QGVAR(feedCam), objNull];
    if (!isNull _cam) then {
        _cam cameraEffect ["Terminate", "Back", DRONES_FEED_RTT];
        camDestroy _cam;
    };
    private _pfh = uiNamespace getVariable [QGVAR(feedPFH), -1];
    if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler};
    uiNamespace setVariable [QGVAR(feedCam), objNull];
    uiNamespace setVariable [QGVAR(feedUav), objNull];
    uiNamespace setVariable [QGVAR(feedPFH), -1];
    uiNamespace setVariable [QGVAR(feedHud), []];
    uiNamespace setVariable [QGVAR(feedTarget), []];
};

if (_mode isNotEqualTo "show" || {isNull _uav} || {!alive _uav}) exitWith {call _fnc_stop};

uiNamespace setVariable [QGVAR(feedHud), _hud];

if ((uiNamespace getVariable [QGVAR(feedUav), objNull]) isEqualTo _uav
    && {!isNull (uiNamespace getVariable [QGVAR(feedCam), objNull])}) exitWith {};

call _fnc_stop;
uiNamespace setVariable [QGVAR(feedHud), _hud];

// The gunner optic's memory points, from the drone's own config - the points
// the vanilla terminal's own picture uses. A drone without them looks ahead
// and down from its centre.
private _posMem = getText (configOf _uav >> "uavCameraGunnerPos");
private _dirMem = getText (configOf _uav >> "uavCameraGunnerDir");

private _cam = "camera" camCreate (getPosATL _uav);
if (_posMem isEqualTo "") then {
    _cam attachTo [_uav, [0, 0, 0]];
} else {
    _cam attachTo [_uav, [0, 0, 0], _posMem];
};
_cam cameraEffect ["Internal", "Back", DRONES_FEED_RTT];
DRONES_FEED_RTT setPiPEffect [0];

uiNamespace setVariable [QGVAR(feedCam), _cam];
uiNamespace setVariable [QGVAR(feedUav), _uav];

uiNamespace setVariable [QGVAR(feedPFH), [{
    params ["_args"];
    _args params ["_uav", "_cam", "_posMem", "_dirMem", "_fnc_stop"];

    if (
        !(["drones"] call EFUNC(tacpad,appAlive))
        || {(uiNamespace getVariable [QGVAR(dronesTab), "fleet"]) isNotEqualTo "fleet"}
        || {(uiNamespace getVariable [QGVAR(dronesPick), objNull]) isNotEqualTo _uav}
        || {!alive _uav}
        || {isNull _cam}
    ) exitWith {call _fnc_stop};

    // Steer with the optic. Attached, so the direction is in the drone's
    // model space - the wiki's own PiP recipe.
    private _dir = if (_posMem isEqualTo "" || _dirMem isEqualTo "") then {
        DRONES_FEED_LOOK
    } else {
        (_uav selectionPosition [_posMem, "Memory"]) vectorFromTo (_uav selectionPosition [_dirMem, "Memory"])
    };
    _cam setVectorDirAndUp [_dir, _dir vectorCrossProduct [-(_dir select 1), _dir select 0, 0]];

    if (diag_tickTime < (_cam getVariable [QGVAR(hudNext), 0])) exitWith {};
    _cam setVariable [QGVAR(hudNext), diag_tickTime + DRONES_HUD_TICK];

    // Where the optic points, on the ground: the target grid and range.
    private _from = AGLToASL (_cam modelToWorld [0, 0, 0]);
    private _look = _from vectorAdd ((vectorDir _cam) vectorMultiply DRONES_FEED_RANGE);
    private _hit = (lineIntersectsSurfaces [_from, _look, _uav, _cam, true, 1, "VIEW", "GEOM"]) param [0, []];
    private _tgt = if (_hit isEqualTo []) then {
        uiNamespace setVariable [QGVAR(feedTarget), []];
        ""
    } else {
        private _p = _hit select 0;
        uiNamespace setVariable [QGVAR(feedTarget), ASLToAGL _p];
        format ["TGT %1 - %2 M", mapGridPosition (ASLToAGL _p), round (_from vectorDistance _p)]
    };

    // LASING: the lased grid takes the target line - the designator's own spot
    // when the engine has one, else the point the drone was ordered onto
    // (jmfsb_devices_uavLase, public from its owner).
    private _spot = laserTarget _uav;
    private _lase = if (isNull _spot) then {_uav getVariable [QEGVAR(devices,uavLase), []]} else {getPosATL _spot};
    if (_lase isNotEqualTo []) then {
        _tgt = format ["LASE %1 - %2 M", mapGridPosition _lase, round (_uav distance _lase)];
    };

    private _q = [RADIO_NET_DATA] call FUNC(radioRfQuality);
    private _texts = createHashMapFromArray [
        ["id", format ["%1 - EO", toUpper getText (configOf _uav >> "displayName")]],
        ["nav", format ["ALT %1 - SPD %2 - HDG %3", round ((getPosATL _uav) select 2), round (speed _uav), round (getDir _uav)]],
        ["tgt", [_tgt, "TGT --"] select (_tgt isEqualTo "")],
        ["link", ["LINK --", format ["LINK %1", _q toFixed 2]] select (_q >= 0)]
    ];
    private _colour = (["ground"] call EFUNC(tacpad,theme)) call BIS_fnc_colorRGBAtoHTML;
    {
        _x params ["_ctrl", "_id", "_size", "_align"];
        if (isNull _ctrl) then {continue};
        _ctrl ctrlSetStructuredText parseText format [
            "<t font='RobotoCondensedBold' size='%1' align='%2' color='%3'>%4</t>",
            _size, _align, _colour, [_texts getOrDefault [_id, ""]] call EFUNC(tacpad,xmlSafe)
        ];
    } forEach (uiNamespace getVariable [QGVAR(feedHud), []]);
}, 0, [_uav, _cam, _posMem, _dirMem, _fnc_stop]] call CBA_fnc_addPerFrameHandler];
