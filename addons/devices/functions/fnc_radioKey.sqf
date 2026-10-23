#include "script_component.hpp"
/*
 * Author: JMSB
 * A key pressed while the small devices' RADIO app is open: the soft keys F1-F4
 * (what FUNC(radioRows) labels them on this tab), the cursor (numpad 0 / .),
 * and the tabs (numpad 7 / 8). docs/DESIGN_VOICE.md, "Adding a caller on the
 * phone or side device": open RADIO, move to the person with 0 / ., press F1.
 * Group add: F3 GROUP +, move to the group, F1.
 *
 * Arguments:
 * 0: Key - 0..3 for F1..F4, KEY_INDEX_LEFT / KEY_INDEX_RIGHT for the cursor,
 *    RADIO_TAB_PREV / RADIO_TAB_NEXT for the tabs <NUMBER>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [0] call jmfsb_devices_fnc_radioKey
 *
 * Public: No
 */

params [["_key", -1, [0]]];

if (!GVAR(radioOpen) || {isNil QEFUNC(voice,netState)}) exitWith {false};

private _redraw = {
    [] call FUNC(overlayTick);
    true
};

if (_key in [RADIO_TAB_PREV, RADIO_TAB_NEXT]) exitWith {
    private _at = RADIO_APP_TABS find GVAR(radioTab);
    private _step = [-1, 1] select (_key isEqualTo RADIO_TAB_NEXT);
    GVAR(radioTab) = RADIO_APP_TABS select ((_at + _step + count RADIO_APP_TABS) mod count RADIO_APP_TABS);
    GVAR(radioCursor) = 0;
    GVAR(radioGroupMode) = false;
    call _redraw
};

private _view = [] call FUNC(radioRows);
private _rows = _view get "rows";
private _chips = _view get "chips";
private _count = [count _rows, count _chips] select GVAR(radioGroupMode);

if (_key in [KEY_INDEX_LEFT, KEY_INDEX_RIGHT]) exitWith {
    if (_count > 0) then {
        private _step = [-1, 1] select (_key isEqualTo KEY_INDEX_RIGHT);
        GVAR(radioCursor) = (GVAR(radioCursor) + _step + _count) mod _count;
    };
    call _redraw
};

if (_key < 0 || _key >= SOFT_KEY_COUNT) exitWith {false};
if !(((_view get "keys") param [_key, ["", false]]) param [1, false]) exitWith {true};

// A ring owns F1 and F4 on every tab.
private _ring = _view get "ring";
if (_ring isNotEqualTo "" && {_key in [0, SOFT_KEY_COUNT - 1]}) exitWith {
    [_ring] call ([EFUNC(voice,callAccept), EFUNC(voice,callDecline)] select (_key isEqualTo SOFT_KEY_COUNT - 1));
    call _redraw
};

// BACK closes the app; on CALLS, F4 is HANG UP while a call is up.
private _live = _view get "live";
if (_key isEqualTo SOFT_KEY_COUNT - 1) exitWith {
    if (GVAR(radioTab) isEqualTo "calls" && _live isNotEqualTo "") then {
        [_live] call EFUNC(voice,hangUp);
    } else {
        [false] call FUNC(radioApp);
    };
    call _redraw
};

private _row = _rows param [GVAR(radioCursor), []];
switch (GVAR(radioTab)) do {
    case "calls": {
        if (_key isEqualTo 2) exitWith {
            GVAR(radioGroupMode) = !GVAR(radioGroupMode);
            GVAR(radioCursor) = 0;
        };
        if (GVAR(radioGroupMode)) exitWith {
            private _members = [];
            if (_live isNotEqualTo "") then {
                private _calls = ([] call EFUNC(voice,calls)) select {(_x param [0, ""]) isEqualTo _live};
                _members = (_calls param [0, []]) param [2, []];
            };
            private _group = (RADIO_CHIPS param [GVAR(radioCursor), [""]]) select 0;
            private _units = [_group, _members] call EFUNC(tacpad_apps,radioGroup);
            if (_units isNotEqualTo []) then {[_units] call EFUNC(tacpad_apps,radioDial)};
            GVAR(radioGroupMode) = false;
            GVAR(radioCursor) = 0;
        };
        (_row param [3, []]) params [["_unit", objNull, [objNull]], ["_reachable", false, [false]], ["_mine", false, [false]]];
        if (isNull _unit || _mine) exitWith {};
        if (!_reachable) exitWith {[_unit] call EFUNC(voice,callBack)};
        // F1 ADD rings him into the call (or opens one); F2 CALL opens a call
        // of their own.
        if (_key isEqualTo 0) then {
            [[_unit]] call EFUNC(tacpad_apps,radioDial);
        } else {
            [[_unit], CALL_ROUTINE] call EFUNC(voice,call);
        };
    };
    case "manage": {};
    default {
        private _netId = _row param [3, ""];
        if (_netId isEqualTo "") exitWith {};
        private _state = ([] call EFUNC(voice,netState)) select {(_x param [0, ""]) isEqualTo _netId};
        (_state param [0, []]) params ["", "", "", "", ["_muted", false, [false]], ["_ear", "B", [""]]];
        switch (_key) do {
            case 0: {[_netId, !_muted] call EFUNC(voice,setMute)};
            case 1: {[_netId, EARS select (((EARS find _ear) + 1) mod count EARS)] call EFUNC(voice,setEar)};
            case 2: {[_netId] call EFUNC(voice,setActive)};
        };
    };
};

call _redraw
