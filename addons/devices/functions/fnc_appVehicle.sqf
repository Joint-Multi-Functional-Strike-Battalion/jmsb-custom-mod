#include "script_component.hpp"
/*
 * Author: JMSB
 * VEHICLE STATUS: the vehicle tablet's own app (user, 2026-10-19: "there
 * should be a vehicle status app only on the vehicle term"). One page for the
 * vehicle the tablet was opened from:
 *
 *   DAMAGE + FUEL              every part group green / amber / red, the tank
 *                              and a rough range on it
 *   AMMUNITION + COUNTERMEAS.  turret by turret and weapon by weapon, rounds
 *                              and magazines; smoke and flares apart
 *   CREW + APS + VOICE NETS    who sits where (ON BOARD's own read), the APS
 *                              charges and holds, the voice nets aboard
 *
 * Over them a strip: the vehicle's callsign and type (the type only when the
 * callsign is not already it), speed and engine.
 *
 * ONLY ON THE VEHICLE TABLET. It is registered with the shell when the vehicle
 * tablet opens and taken out when it closes (FUNC(onLoad), FUNC(onUnload)), so
 * no other host has it to offer - no tile, no F-key, no place in the arrows'
 * ring. Read-only: it shows what the engine and the owning systems already
 * know, and changes nothing.
 *
 * REFRESHED ON A TIMER ONLY WHILE OPEN: a CBA loop that redraws through the
 * shell every VEHICLE_APP_TICK seconds, holds while the cursor is on the page
 * (jmfsb_tacpad_fnc_appIdle) and removes itself the moment the page is no
 * longer the open app. STARTED ONCE, NOT ON EVERY DRAW: the loop's own redraw
 * comes back through here, and a fresh CBA handler runs on the very next
 * frame - restarting it per draw turned the two-second tick into a redraw
 * every frame. Its handle is GVAR(vehiclePFH), in missionNamespace, so a
 * mission that ends with the page open leaves no stale handle behind.
 *
 * Arguments (app handler):
 * 0: The host display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["vehicle", [], true] call jmfsb_tacpad_fnc_openApp
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {};

private _vehicle = GVAR(vehicle);
private _columns = [_vehicle] call FUNC(vehicleLines);

// MEASURED BEFORE IT IS BUILT: the page is as tall as its longest column, in
// rows of the shell's own height, and never taller than the map area.
private _rowFraction = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale);
private _units = 0;
{
    private _columnUnits = 0;
    {
        _columnUnits = _columnUnits + (switch (_x select 0) do {
            case "head": {VEHICLE_HEAD_ROWS};
            case "gap": {VEHICLE_GAP_ROWS};
            default {1};
        });
    } forEach _x;
    _units = _units max _columnUnits;
} forEach _columns;

([_display, VEHICLE_APP_TITLE, VEHICLE_APP_W, ((_units + VEHICLE_APP_SPARE_ROWS) * _rowFraction) min 1] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent", "_line"];
private _muted = ["muted"] call EFUNC(tacpad,theme);

(ctrlPosition _body) params ["", "", "_w", "_h"];
private _rowH = _rowFraction * HOST_H;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

// ---------------------------------------------------------------- strip ----
private _name = [_vehicle] call FUNC(vehicleName);
private _type = if (isNull _vehicle) then {"NO VEHICLE"} else {toUpper getText (configOf _vehicle >> "displayName")};
private _state = switch (true) do {
    case (isNull _vehicle): {""};
    case (!alive _vehicle): {"DESTROYED"};
    default {
        format ["%1 KM/H  %2  ENGINE %3", round abs speed _vehicle, MIDDOT, ["OFF", "ON"] select (isEngineOn _vehicle)]
    };
};
private _title = [format ["%1  %2  %3", _name, MIDDOT, _type], _type] select (_name isEqualTo _type || _name isEqualTo "");
[_body, [_pad, _padY, _w * VEHICLE_STRIP_SPLIT, _rowH], _title, _ink, VEHICLE_TEXT_STRIP, true] call EFUNC(tacpad,drawText);

// DESTROYED is the inverted block, as every red on the page is - the accent is
// not red on every scheme, so the fill and the word carry it, not the hue.
private _stateRect = [_w * VEHICLE_STRIP_SPLIT, _padY, _w * (1 - VEHICLE_STRIP_SPLIT) - _pad, _rowH];
private _stateInk = _muted;
if (!isNull _vehicle && {!alive _vehicle}) then {
    _stateInk = ["ground"] call EFUNC(tacpad,theme);
    private _blockH = _rowH * VEHICLE_BLOCK_ROW;
    [_body, [_stateRect select 0, _padY + (_rowH - _blockH) * 0.5, _stateRect select 2, _blockH], _accent] call EFUNC(tacpad,drawFill);
    _stateRect set [2, (_stateRect select 2) - _pad];
};
[_body, _stateRect, _state, _stateInk, VEHICLE_TEXT_ROW, true, "right"] call EFUNC(tacpad,drawText);
private _top = _padY + _rowH + _padY;
[_body, [0, _top, _w, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_top = _top + RULE_THICK * pixelH + _padY;

// -------------------------------------------------------------- columns ----
private _x0 = 0;
{
    private _columnW = _w * (VEHICLE_COLUMNS select _forEachIndex);
    if (_forEachIndex > 0) then {
        [_body, [_x0, _top, RULE_THIN * pixelW, _h - _top - _padY], _line] call EFUNC(tacpad,drawFill);
    };
    [_body, [_x0, _top, _columnW, _h - _padY], _x] call FUNC(vehicleColumn);
    _x0 = _x0 + _columnW;
} forEach _columns;

// ------------------------------------------------------------- the timer ----
// Once: a close and reopen inside one tick finds the loop still running and
// it simply carries on.
if (GVAR(vehiclePFH) < 0) then {
    GVAR(vehiclePFH) = [{
        params ["", "_handle"];

        if !([VEHICLE_APP] call EFUNC(tacpad,appAlive)) exitWith {
            [_handle] call CBA_fnc_removePerFrameHandler;
            GVAR(vehiclePFH) = -1;
        };

        if !([] call EFUNC(tacpad,appIdle)) exitWith {};
        [VEHICLE_APP] call EFUNC(tacpad,openApp);
    }, VEHICLE_APP_TICK, []] call CBA_fnc_addPerFrameHandler;
};
