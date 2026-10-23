#include "script_component.hpp"
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"
/*
 * Author: JMSB
 * THE APS PANEL ON THE MAP (user, 2026-08-29: "APS should be on vehicles based
 * on their tier with a live panel to control APS on the map"). One block per
 * fitted vehicle the player is entitled to see - the one they are in first,
 * then the group's or the side's by distance, as the Panel Scope setting
 * allows - with the fit the tier table gave it, the charges by side, the
 * emitter's state, and three switches:
 *
 *   HK ON / HK HOLD    the launchers fire on their own, or not at all
 *   RF AUTO / RF HOLD  the emitter fires on its own, or only when told to
 *   BURST              fire the emitter now, if it is live and off cooldown
 *
 * WHY THE HOLDS EXIST. The burst jams every radio near the emitter, friend and
 * foe, and drops own drones too - a section flying a UAV overhead or talking
 * on the net wants the emitter silent until the missile is real. HK HOLD is
 * for the moment the launchers would kill your own rocket team's round.
 *
 * Holds are server state on the vehicle (fnc_setHold), so every crew, every
 * panel and fnc_watch agree; the panel writes the new value locally too so
 * the press is seen at once rather than a network round trip later.
 *
 * Registered with the tacpad shell from XEH_postInit as builder AND
 * refresher, so it redraws every two seconds while the map is open - the
 * charges count down and the cooldown counts up without anyone pressing
 * anything. A soft dependency: without the shell, the APS itself is unchanged.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel id <STRING>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_id", "", [""]]];

if (isNull _body) exitWith {};

{ ctrlDelete _x } forEach (allControls (ctrlParent _body) select { (ctrlParentControlsGroup _x) isEqualTo _body });

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _w = (ctrlPosition _body) # 2;
// HOST UNITS, like every shell panel: on a tablet the host is the map area,
// not the monitor, and FUNC(fit) multiplies what it is handed by HOST_H.
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];
private _amber = [0.85, 0.65, 0.15, 1];

private _list = call FUNC(panelList);
private _y = _padY;

// Nothing to show says WHY, in the scope's own words - "no fitted vehicle in
// the group" is an answer, an empty panel is not.
if (_list isEqualTo []) exitWith {
    private _why = if !(missionNamespace getVariable [QGVAR(enabled), true]) then { "APS IS OFF" } else {
        ["NOT IN A FITTED VEHICLE", "NO FITTED VEHICLE IN THE GROUP", "NO FITTED VEHICLE ON THE SIDE"]
            select (((missionNamespace getVariable [QGVAR(panelScope), 1]) max 0) min 2)
    };
    [_body, [_pad, _y, _w - 2 * _pad, _rowH], _why, _dim, 0.75, true, "left", true] call EFUNC(tacpad,drawText);
    [_id, 0, (_y + _rowH + _padY) / HOST_H] call EFUNC(tacpad,fit);
};

private _mine = vehicle player;
private _now = CBA_missionTime;
private _btnW = (_w - 4 * _pad) / 3;
private _btnH = _rowH * 1.1;

// The press. The button carries its vehicle and its action; the server is the
// one arbiter of both, and the panel redraws next frame to show the press.
private _onPress = {
    params ["_ctrl"];
    private _veh = _ctrl getVariable [QGVAR(veh), objNull];
    (_ctrl getVariable [QGVAR(action), []]) params [["_what", "", [""]], ["_value", false, [false]]];
    if (isNull _veh || _what isEqualTo "") exitWith {};

    if (_what isEqualTo "burst") then {
        [_veh] remoteExec [QFUNC(burstNow), 2];
    } else {
        // shown at once; the server's public write lands a moment later and agrees
        _veh setVariable [[QGVAR(hkHold), QGVAR(rfHold)] select (_what isEqualTo "rf"), _value];
        [_veh, _what, _value] remoteExec [QFUNC(setHold), 2];
    };
    { ["aps"] call EFUNC(tacpad,rebuild) } call CBA_fnc_execNextFrame;
};

{
    private _veh = _x;

    if (_forEachIndex > 0) then {
        [_body, [_pad, _y, _w - 2 * _pad, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
        _y = _y + _padY;
    };

    private _fit = _veh getVariable [QGVAR(fit), FIT_NONE];
    private _rf = _veh getVariable [QGVAR(rf), false];
    private _hkHold = _veh getVariable [QGVAR(hkHold), false];
    private _rfHold = _veh getVariable [QGVAR(rfHold), false];
    private _max = _veh getVariable [QGVAR(ammoMax), 0];
    private _live = alive _veh && {isEngineOn _veh} && {(crew _veh) isNotEqualTo []};
    private _left = (_veh getVariable [QGVAR(rfReady), 0]) - _now;

    // ---- the vehicle, and where it is --------------------------------------
    private _label = toUpper getText (configOf _veh >> "displayName");
    private _where = if (_veh == _mine) then { "YOU" } else {
        format ["%1 KM  %2", (round ((player distance _veh) / 100)) / 10, [round (player getDir _veh), 3] call CBA_fnc_formatNumber]
    };
    [_body, [_pad, _y, _w * 0.62, _rowH], _label, _ink, 0.8, true] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.62, _y, _w * 0.38 - _pad, _rowH], _where, _mute, 0.62, true, "right", true] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;

    // ---- the system, its charges, the emitter ---------------------------------
    [_body, [_pad, _y, _w * 0.4, _rowH], _veh getVariable [QGVAR(name), "APS"], _mute, 0.62, true, "left", true] call EFUNC(tacpad,drawText);
    private _status = [];
    private _colour = _ink;
    if (_fit isNotEqualTo FIT_NONE && _max > 0) then {
        private _l = _veh getVariable [QGVAR(ammoL), 0];
        private _r = _veh getVariable [QGVAR(ammoR), 0];
        _status pushBack format ["L %1/%2  R %3/%4", _l, _max, _r, _max];
        if (_l + _r <= 0) then { _colour = _accent };
        if (_hkHold) then { _colour = _amber };
    };
    if (_rf) then {
        _status pushBack (switch (true) do {
            case (!_live): { "RF COLD" };
            case (_left > 0): { format ["RF %1s", ceil _left] };
            case (_rfHold): { "RF HOLD" };
            default { "RF READY" };
        });
    };
    [_body, [_w * 0.4, _y, _w * 0.6 - _pad, _rowH], _status joinString "   ", _colour, 0.62, true, "right", true] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;

    // ---- the switches ------------------------------------------------------------
    // [label, lit, pressable, action]. A switch that is ON is drawn plain and
    // a HOLD in the accent, so a panel full of quiet systems reads as quiet;
    // BURST is greyed until the emitter could actually fire.
    private _buttons = [];
    if (_fit isNotEqualTo FIT_NONE) then {
        _buttons pushBack [["HK ON", "HK HOLD"] select _hkHold, _hkHold, true, ["hk", !_hkHold]];
    };
    if (_rf) then {
        _buttons pushBack [["RF AUTO", "RF HOLD"] select _rfHold, _rfHold, true, ["rf", !_rfHold]];
        _buttons pushBack ["BURST", false, _live && _left <= 0, ["burst", true]];
    };
    {
        _x params ["_text", "_lit", "_pressable", "_action"];
        private _bx = _pad + _forEachIndex * (_btnW + _pad);
        [_body, [_bx, _y, _btnW, _btnH], [_line, _accent] select _lit, RULE_THIN] call EFUNC(tacpad,drawFrame);
        [
            _body, [_bx, _y, _btnW, _btnH], _text,
            [[_dim, _ink] select _pressable, _accent] select _lit,
            0.62, true, "center", true
        ] call EFUNC(tacpad,drawText);
        if (_pressable) then {
            private _hit = [_body, [_bx, _y, _btnW, _btnH], _onPress] call EFUNC(tacpad,drawHit);
            _hit setVariable [QGVAR(veh), _veh];
            _hit setVariable [QGVAR(action), _action];
        };
    } forEach _buttons;
    if (_buttons isNotEqualTo []) then { _y = _y + _btnH + _padY };
} forEach _list;

[_id, 0, (_y + _padY) / HOST_H] call EFUNC(tacpad,fit);
