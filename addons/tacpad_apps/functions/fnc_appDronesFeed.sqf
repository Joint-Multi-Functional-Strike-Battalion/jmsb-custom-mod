#include "script_component.hpp"
/*
 * Author: JMSB
 * DRONES - FEED: the picked drone's camera as a picture inside the app
 * (render-to-texture, FUNC(appDronesCamera)), with the HUD the design draws -
 * name, altitude, speed, heading, target grid and range, link - and the
 * control buttons under it.
 *
 * BUTTONS (FUNC(appDronesAction)): CONNECT / DISCONNECT where the devices'
 * drone link allows it (no UAV terminal, jmfsb_devices_fnc_uavCan: the UAV
 * operator, the players' side, nobody else's, the DATA link). TAKE CONTROL,
 * ORBIT, GO TO (a map pick, FUNC(appDronesPick)), LASE / LASE OFF and RTB on
 * the drone he has linked, while the DATA link holds; the press asks the gate
 * again. MARK TARGET always. LASE on an airframe with no designator says so.
 *
 * MODE: a Drone40 variant (jmfsb_drone40) gets a row of RELAY / DECOY /
 * JAMMER / OFF above the buttons, its mode filled, live on the same gate as
 * CONNECT (jmfsb_drone40_fnc_setMode).
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appDrones)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appDronesFeed
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _fleet = _ctx get "fleet";
private _pick = _ctx get "pick";
private _rowH = _ctx get "rowH";

private _iRow = _fleet findIf {(_x select 0) isEqualTo _pick};
private _row = if (_iRow < 0) then {[]} else {_fleet select _iRow};
private _name = _row param [1, ""];

([_body, _rect, ["FEED", format ["FEED - %1", _name]] select (_name isNotEqualTo ""), "CONTROL NEEDS DATA LINK"] call FUNC(appPagePanel)) params ["_left", "_top", "_w", "_h"];

private _ground = ["ground"] call EFUNC(tacpad,theme);
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _btnH = _rowH * 1.2;

// One row of buttons, two for a Drone40 (its MODE row).
private _modeNow = _row param [13, ""];
private _btnRows = [1, 2] select (_modeNow isNotEqualTo "");
private _screen = [_left + _pad, _top + _padY, _w - 2 * _pad, _h - _btnRows * (_btnH + _padY) - _padY * 3];
_screen params ["_sx", "_sy", "_sw", "_sh"];
[_body, _screen, _ink] call EFUNC(tacpad,drawFill);

if (_row isEqualTo []) exitWith {
    ["stop"] call FUNC(appDronesCamera);
    [_body, [_sx + _pad, _sy + _sh * 0.45, _sw - 2 * _pad, _rowH], "NO DRONE PICKED", _ground, TEXT_TITLE, true, "center", true] call EFUNC(tacpad,drawText);
};

_row params ["_uav", "", "_word", "_q", "", "", "_mine", "", "_can", "", ["_why", ""], ["_lasing", false]];

// THE PICTURE. Rebuilt with the page; the camera behind it is not.
private _picture = (ctrlParent _body) ctrlCreate ["RscPicture", -1, _body];
_picture ctrlSetPosition _screen;
_picture ctrlSetText format ["#(argb,%1,%1,1)r2t(%2,1.0)", DRONES_FEED_RES, DRONES_FEED_RTT];
_picture ctrlCommit 0;

// THE HUD: an ink strip top and bottom, two lines each, kept current by the
// feed's own handler rather than by rebuilding the board.
private _stripH = _rowH * 1.1;
[_body, [_sx, _sy, _sw, _stripH], _ink] call EFUNC(tacpad,drawFill);
[_body, [_sx, _sy + _sh - _stripH, _sw, _stripH], _ink] call EFUNC(tacpad,drawFill);

private _hud = [];
{
    _x params ["_id", "_y", "_align"];
    private _ctrl = [_body, [_sx + _pad, _y, _sw - 2 * _pad, _stripH], "", _ground, TEXT_LABEL, true, _align] call EFUNC(tacpad,drawText);
    _hud pushBack [_ctrl, _id, 0.6, _align];
} forEach [
    ["id", _sy, "left"],
    ["nav", _sy, "right"],
    ["tgt", _sy + _sh - _stripH, "left"],
    ["link", _sy + _sh - _stripH, "right"]
];
["show", _uav, _hud] call FUNC(appDronesCamera);

// ------------------------------------------------------------- buttons ---
private _linkLost = _q >= 0 && _q < DRONE_LINK_LOST;
private _fnc_act = {
    params ["_ctrl"];
    (_ctrl getVariable [QGVAR(pageData), []]) params ["_action", "_uav", ["_arg", ""]];
    [_action, _uav, _arg] call FUNC(appDronesAction);
    {["drones"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
};

private _order = _mine && !_linkLost;
private _buttons = [
    [["CONNECT", "DISCONNECT"] select _mine, ["connect", "disconnect"] select _mine, _mine || {_can && !_linkLost}, "fill"],
    ["TAKE CONTROL", "control", _order, "line"],
    ["ORBIT", "orbit", _order, "line"],
    ["MARK TARGET", "mark", true, "line"],
    ["GO TO", "goto", _order, "line"],
    [["LASE", "LASE OFF"] select _lasing, "lase", _order, ["line", "alarm"] select _lasing],
    ["RTB", "rtb", _order, "line"]
];
private _btnY = _top + _h - _btnH - _padY;
private _btnW = (_w - _pad * (count _buttons + 1)) / (count _buttons);
{
    _x params ["_label", "_action", "_live", "_style"];
    [
        _body, [_left + _pad + _forEachIndex * (_btnW + _pad), _btnY, _btnW, _btnH], _label,
        _style,
        [{}, _fnc_act] select _live,
        [_action, _uav]
    ] call FUNC(appPageButton);
} forEach _buttons;

// THE DRONE40 MODE ROW, over the buttons: its word, then one segment per mode.
private _topRowY = _btnY;
if (_modeNow isNotEqualTo "") then {
    _topRowY = _btnY - _btnH - _padY;
    private _modeLive = (_mine || _can) && !_linkLost;
    private _labelW = _btnW;
    [_body, [_left + _pad, _topRowY, _labelW, _btnH], "MODE", _dim, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    private _segX = _left + _pad * 2 + _labelW;
    private _segW = (_left + _w - _pad - _segX - _pad * (count DRONES_MODES - 1)) / (count DRONES_MODES);
    {
        _x params ["_id", "_label"];
        [
            _body, [_segX + _forEachIndex * (_segW + _pad), _topRowY, _segW, _btnH], _label,
            ["line", "fill"] select (_id isEqualTo _modeNow),
            [{}, _fnc_act] select _modeLive,
            ["mode", _uav, _id]
        ] call FUNC(appPageButton);
    } forEach DRONES_MODES;
};

// Why CONNECT is dead, in the gate's own words (jmfsb_devices_fnc_uavCan) -
// there is no terminal to blame any more.
if (!_can && !_mine) then {
    [_body, [_left + _pad, _topRowY - _rowH, _w - 2 * _pad, _rowH], _why, _dim, TEXT_LABEL] call EFUNC(tacpad,drawText);
};
