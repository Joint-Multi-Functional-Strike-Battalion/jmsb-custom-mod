#include "script_component.hpp"
/*
 * Author: JMSB
 * POINT MAN, the page (user, 2026-10-30): a grid box and ADD, PICK ON MAP,
 * FOLLOW (a list of the BFT friendlies; press one and a waypoint walks with
 * him, FUNC(follow)), the waypoints in order with their distance and bearing
 * from where the GPS says the player is, USE / STOP and CLEAR ALL, and the
 * route's ELEVATION PROFILE as a strip of bars (FUNC(profile)). Pressing a
 * waypoint makes it the next one; DEL takes it out. The route is on every
 * map the moment a waypoint exists (FUNC(draw)); USE walks it and puts the
 * distance on the phone (FUNC(cell)) and the tablet bar (FUNC(navText)).
 *
 * IT REDRAWS ITSELF every PM_REFRESH seconds while open, through the same
 * appAlive / appIdle pair every live app uses, so the distances walk - but
 * not while a grid is being typed: a redraw takes the box from under it.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["pointman", [], true] call jmfsb_tacpad_fnc_openApp
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

private _wps = GVAR(waypoints);
private _scale = EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale);
// The FOLLOW list and the profile strip are open or not, per page; each
// adds its rows to the page's height.
private _followOpen = uiNamespace getVariable [QGVAR(followOpen), false];
private _contacts = if (_followOpen) then {[] call FUNC(contacts)} else {[]};
private _profileOpen = uiNamespace getVariable [QGVAR(profileOpen), false];
private _profile = if (_profileOpen) then {[] call FUNC(profile)} else {[]};
private _extra = (count _wps) + ([0, ((count _contacts) max 1) + 1] select _followOpen) + ([0, PROFILE_ROWS + 1] select (_profile isNotEqualTo []));
([_display, APP_TITLE, APP_W, APP_H_BASE + _extra * ROW_H * _scale] call EFUNC(tacpad,appFrame)) params ["_group", "_body"];
// A control lives in uiNamespace: in the mission namespace it cannot be saved.
uiNamespace setVariable [QGVAR(group), _group];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _rowH = ROW_H * _scale * HOST_H;
private _w = (ctrlPosition _body) select 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _inner = _w - 2 * _pad;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];
private _wash = [_accent # 0, _accent # 1, _accent # 2, 0.12];
private _btnH = ([TEXT_TITLE] call EFUNC(tacpad,textH)) + 2 * _padY;

// A button: an outline, a word, the press, and what the press reads.
private _fnc_button = {
    params ["_rect", "_label", "_colour", "_code"];
    [_body, _rect, _colour, RULE_THIN] call EFUNC(tacpad,drawFrame);
    [_body, _rect, _label, _colour, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
    private _hit = [_body, _rect, _code] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(data), _this param [4, -1]];
    _hit
};

// ------------------------------------------------------- the grid box ----
private _y = _padY;
private _labW = _w * 0.1;
[_body, [_pad, _y, _labW, _btnH], "GRID", _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
private _boxX = _pad + _labW;
private _boxW = _w * 0.3;
[_body, [_boxX, _y, _boxW, _btnH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
private _box = (ctrlParent _body) ctrlCreate ["RscEdit", -1, _body];
_box ctrlSetPosition [_boxX + _pad, _y, _boxW - 2 * _pad, _btnH];
_box ctrlSetBackgroundColor [0, 0, 0, 0];
_box ctrlSetTextColor _ink;
_box ctrlSetFontHeight (_btnH * 0.72);
_box ctrlSetText (uiNamespace getVariable [QGVAR(gridText), ""]);
_box ctrlSetTooltip "A grid - 6, 8 or 10 figures - then ADD. The numpad types here.";
_box ctrlCommit 0;
_box ctrlAddEventHandler ["KeyUp", {
    params ["_ctrl"];
    uiNamespace setVariable [QGVAR(gridText), ctrlText _ctrl];
    false
}];

private _bx = _boxX + _boxW + _pad;
private _addW = _w * 0.12;
[[_bx, _y, _addW, _btnH], "ADD", _accent, {
    if ([uiNamespace getVariable [QGVAR(gridText), ""]] call FUNC(addGrid)) then {
        uiNamespace setVariable [QGVAR(gridText), ""];
    };
    {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_button;
_bx = _bx + _addW + _pad;
private _pickW = _w * 0.22;
[[_bx, _y, _pickW, _btnH], "PICK ON MAP", _ink, {["arm"] call FUNC(pick)}] call _fnc_button;
_bx = _bx + _pickW + _pad;
[[_bx, _y, _w - _bx - _pad, _btnH], ["FOLLOW", "CLOSE LIST"] select _followOpen, [_ink, _accent] select _followOpen, {
    uiNamespace setVariable [QGVAR(followOpen), !(uiNamespace getVariable [QGVAR(followOpen), false])];
    {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_button;
_y = _y + _btnH + _padY;

// ------------------------------------------------------------ the contacts ----
// FOLLOW (user, 2026-10-30): the BFT friendlies, nearest first; press one and
// a waypoint walks with him (FUNC(follow)).
if (_followOpen) then {
    [_body, [_pad, _y, _inner, _rowH], "FOLLOW - PRESS A MAN; HIS VEHICLE COMES WITH HIM", _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;
    if (_contacts isEqualTo []) then {
        [_body, [_pad, _y, _inner, _rowH], "NO FRIENDLIES TO FOLLOW", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
        _y = _y + _rowH;
    } else {
        {
            _x params ["_unit", "_label", "_groupId", "_dist"];
            private _ry = _y + _forEachIndex * _rowH;
            private _distText = if (_dist < 0) then {"--"} else {[_dist] call EFUNC(maptools,distanceText)};
            [_body, [_pad, _ry, _inner * 0.5, _rowH], _label, _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);
            [_body, [_pad + _inner * 0.5, _ry, _inner * 0.3, _rowH], toUpper _groupId, _mute, TEXT_BODY, true] call EFUNC(tacpad,drawText);
            [_body, [_pad + _inner * 0.8, _ry, _inner * 0.2, _rowH], _distText, _ink, TEXT_BODY, true, "right"] call EFUNC(tacpad,drawText);
            private _hit = [_body, [_pad, _ry, _inner, _rowH], {
                params ["_ctrl"];
                [_ctrl getVariable [QGVAR(data), objNull]] call FUNC(follow);
                uiNamespace setVariable [QGVAR(followOpen), false];
                {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            }] call EFUNC(tacpad,drawHit);
            _hit setVariable [QGVAR(data), _unit];
        } forEach _contacts;
        _y = _y + (count _contacts) * _rowH;
    };
    [_body, [_pad, _y, _inner, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
    _y = _y + _padY;
};

// -------------------------------------------------------- the waypoints ----
// Column starts as shares of the row: #, GRID, DIST, BRG, DEL.
private _cols = [0, 0.08, 0.5, 0.68, 0.84];
private _cx = _cols apply {_pad + _x * _inner};
private _cw = [];
{
    _cw pushBack ((_cx param [_forEachIndex + 1, _pad + _inner]) - _x - _pad * 0.5);
} forEach _cx;
{
    [_body, [_cx select _forEachIndex, _y, _cw select _forEachIndex, _rowH], _x, _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
} forEach ["#", "GRID", "DIST", "BRG"];
_y = _y + _rowH;
[_body, [_pad, _y, _inner, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

([] call FUNC(state)) params ["_nav", "", "", "", "_navDist", "_navBrg"];
private _here = [] call FUNC(gpsPos);
if (_wps isEqualTo []) then {
    [_body, [_pad, _y, _inner, _rowH], "NO WAYPOINTS - TYPE A GRID AND ADD, OR PICK ON MAP", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;
} else {
    {
        _x params ["", "_label"];
        // Where it is now: a FOLLOW waypoint moves with its man.
        private _pos = [_x] call FUNC(wpPos);
        private _ry = _y + _forEachIndex * _rowH;
        private _live = _forEachIndex isEqualTo GVAR(next);
        private _colour = [_ink, _accent] select _live;
        if (_live) then {[_body, [_pad, _ry, _inner, _rowH], _wash] call EFUNC(tacpad,drawFill)};

        private _dist = "--";
        private _brg = "--";
        if (_here isNotEqualTo []) then {
            _dist = [_here distance2D _pos] call EFUNC(maptools,distanceText);
            _brg = [_here getDir _pos] call EFUNC(maptools,bearingText);
        };
        {
            [_body, [_cx select _forEachIndex, _ry, _cw select _forEachIndex, _rowH], _x, _colour, TEXT_BODY, _forEachIndex isEqualTo 0] call EFUNC(tacpad,drawText);
        } forEach [format ["%1%2", _forEachIndex + 1, ["", " >"] select _live], _label, _dist, _brg];

        // The row is the NEXT button: press a waypoint to walk to it first.
        private _hit = [_body, [_pad, _ry, (_cx select 4) - _pad, _rowH], {
            params ["_ctrl"];
            GVAR(next) = _ctrl getVariable [QGVAR(data), 0];
            {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }] call EFUNC(tacpad,drawHit);
        _hit setVariable [QGVAR(data), _forEachIndex];

        // DEL names its row, so "DEL 2" on the key is "2" on the list.
        [[_cx select 4, _ry + _rowH * 0.05, (_cw select 4) - _pad * 0.5, _rowH * 0.9], format ["DEL %1", _forEachIndex + 1], _mute, {
            params ["_ctrl"];
            [_ctrl getVariable [QGVAR(data), -1]] call FUNC(remove);
            {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }, _forEachIndex] call _fnc_button;
    } forEach _wps;
    _y = _y + (count _wps) * _rowH;
};

// ------------------------------------------------------- USE and CLEAR ----
_y = _y + _padY;
private _half = (_w - 3 * _pad) / 2;
[[_pad, _y, _half, _btnH], ["USE - NAVIGATE", "STOP"] select GVAR(navigating), _accent, {
    [!GVAR(navigating)] call FUNC(use);
    {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_button;
[[_pad * 2 + _half, _y, _half, _btnH], "CLEAR ALL", _mute, {
    [] call FUNC(clear);
    {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_button;
_y = _y + _btnH + _padY;

// ------------------------------------------------------- the profile ----
// THE ELEVATION PROFILE (user, 2026-10-30): the ground along the route as a
// strip of bars, low to high over the strip's height, the waypoints' bars in
// the accent; under it the climb, the descent, the lowest and the highest.
[[_pad, _y, _inner, _btnH], ["ELEVATION PROFILE", "HIDE PROFILE"] select _profileOpen, [_ink, _accent] select _profileOpen, {
    uiNamespace setVariable [QGVAR(profileOpen), !(uiNamespace getVariable [QGVAR(profileOpen), false])];
    {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_button;
_y = _y + _btnH + _padY;
if (_profile isNotEqualTo []) then {
    _profile params ["_heights", "_length", "_climb", "_descent", "_low", "_high", "_marks"];
    private _stripH = PROFILE_ROWS * _rowH;
    private _span = (_high - _low) max PROFILE_MIN_SPAN;
    private _barW = _inner / PROFILE_BARS;
    [_body, [_pad, _y, _inner, _stripH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
    {
        private _k = ((_x - _low) / _span) min 1 max 0;
        private _barH = (_stripH * _k) max (RULE_THIN * pixelH);
        [_body, [_pad + _forEachIndex * _barW, _y + _stripH - _barH, _barW, _barH], [_mute, _accent] select (_forEachIndex in _marks)] call EFUNC(tacpad,drawFill);
    } forEach _heights;
    _y = _y + _stripH;
    [_body, [_pad, _y, _inner, _rowH], format ["%1 - CLIMB +%2 M - DESCENT -%3 M - LOW %4 M - HIGH %5 M", [_length] call EFUNC(maptools,distanceText), round _climb, round _descent, round _low, round _high], _mute, TEXT_LABEL] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;
} else {
    if (_profileOpen) then {
        [_body, [_pad, _y, _inner, _rowH], "NO ROUTE TO PROFILE - ADD A WAYPOINT, OR TWO", _dim, TEXT_LABEL] call EFUNC(tacpad,drawText);
        _y = _y + _rowH;
    };
};

private _foot = switch (true) do {
    case (_nav && _navDist < 0): {"NAVIGATING - NO GPS FIX, NO DISTANCE"};
    case (_nav): {format ["NAVIGATING - WP %1 IS %2 AT %3 - ARRIVE AT %4 M", GVAR(next) + 1, [_navDist] call EFUNC(maptools,distanceText), [_navBrg] call EFUNC(maptools,bearingText), GVAR(arriveRadius)]};
    default {format ["%1 OF %2 WAYPOINTS - THE ROUTE IS ON THE MAP - ARRIVE AT %3 M", count _wps, MAX_WAYPOINTS, GVAR(arriveRadius)]};
};
[_body, [_pad, _y, _inner, _rowH], _foot, _mute, TEXT_LABEL] call EFUNC(tacpad,drawText);

// ------------------------------------------------------- the refresh ----
if (GVAR(pfh) >= 0) then {
    [GVAR(pfh)] call CBA_fnc_removePerFrameHandler;
    GVAR(pfh) = -1;
};
GVAR(pfh) = [{
    params ["", "_handle"];
    if !([APP_ID] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        GVAR(pfh) = -1;
    };
    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    if ((uiNamespace getVariable [QGVAR(gridText), ""]) isNotEqualTo "") exitWith {};
    [APP_ID] call EFUNC(tacpad,openApp);
}, PM_REFRESH, []] call CBA_fnc_addPerFrameHandler;
