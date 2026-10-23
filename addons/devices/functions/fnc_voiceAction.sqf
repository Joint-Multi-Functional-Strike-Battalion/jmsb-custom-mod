#include "script_component.hpp"
/*
 * Author: JMSB
 * The walking view's voice actions (docs/DESIGN_VOICE.md, "F-keys on the
 * walking view"), as the device buttons' settings name them (BUTTON_IDS):
 *
 *   callAccept     F1   accept the ringing call; in the quick-add list, add
 *                       the one under the cursor
 *   earQuickAdd    F2   during a call, open or close the quick-add list on
 *                       the notification line; otherwise step the active
 *                       net's ear L > B > R
 *   mute           F3   mute or unmute the active net
 *   declineHangUp  F4   close the quick-add list; else decline the ringing
 *                       call; else hang up
 *   netPrev        0    in the quick-add list, move the cursor; else the
 *   netNext        .    active net one left / right
 *
 * Everything goes through jmfsb_voice's API; nothing here is a radio.
 *
 * Arguments:
 * 0: Action, one of the BUTTON_* voice ids <STRING>
 *
 * Return Value:
 * Acted - the key is consumed <BOOL>
 *
 * Example:
 * [BUTTON_CALL_ACCEPT] call jmfsb_devices_fnc_voiceAction
 *
 * Public: No
 */

params [["_action", "", [""]]];

if (isNil QEFUNC(voice,calls) || {isNil QEFUNC(voice,netState)}) exitWith {false};

private _calls = [] call EFUNC(voice,calls);
private _ring = _calls select {(_x param [1, ""]) isEqualTo CALL_RINGING};
private _live = _calls select {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING]};
private _members = (_live param [0, []]) param [2, []];
if (_live isEqualTo []) then {GVAR(quickOpen) = false};

private _nets = [] call EFUNC(voice,netState);
private _activeIndex = _nets findIf {_x param [3, false]};
private _activeNet = (_nets param [_activeIndex max 0, []]) param [0, ""];
if (_activeIndex < 0) then {_activeNet = ""};

switch (_action) do {
    case BUTTON_CALL_ACCEPT: {
        if (GVAR(quickOpen)) exitWith {
            private _offer = [_members] call EFUNC(tacpad_apps,radioQuick);
            if (_offer isEqualTo []) exitWith {true};
            [[_offer select ((GVAR(quickCursor) max 0) min (count _offer - 1))]] call EFUNC(tacpad_apps,radioDial);
            true
        };
        if (_ring isEqualTo []) exitWith {false};
        [(_ring select 0) select 0] call EFUNC(voice,callAccept);
        true
    };
    case BUTTON_EAR_QUICK: {
        // Quick add is the owner's (user, 2026-10-20); anyone else's F2 stays the ear.
        if (_live isNotEqualTo [] && {[] call EFUNC(tacpad_apps,radioCanAdd)}) exitWith {
            GVAR(quickOpen) = !GVAR(quickOpen);
            GVAR(quickCursor) = 0;
            true
        };
        if (_activeNet isEqualTo "") exitWith {false};
        private _ear = (_nets select _activeIndex) param [5, "B"];
        private _at = EARS find _ear;
        [_activeNet, EARS select ((_at + 1) mod count EARS)] call EFUNC(voice,setEar);
        true
    };
    case BUTTON_MUTE: {
        if (_activeNet isEqualTo "") exitWith {false};
        [_activeNet, !((_nets select _activeIndex) param [4, false])] call EFUNC(voice,setMute);
        true
    };
    case BUTTON_DECLINE: {
        if (GVAR(quickOpen)) exitWith {
            GVAR(quickOpen) = false;
            true
        };
        if (_ring isNotEqualTo []) exitWith {
            [(_ring select 0) select 0] call EFUNC(voice,callDecline);
            true
        };
        if (_live isEqualTo []) exitWith {false};
        [(_live select 0) select 0] call EFUNC(voice,hangUp);
        true
    };
    case BUTTON_NET_PREV;
    case BUTTON_NET_NEXT: {
        private _step = [-1, 1] select (_action isEqualTo BUTTON_NET_NEXT);
        if (GVAR(quickOpen)) exitWith {
            private _count = count ([_members] call EFUNC(tacpad_apps,radioQuick));
            if (_count > 0) then {GVAR(quickCursor) = (GVAR(quickCursor) + _step + _count) mod _count};
            true
        };
        [_step] call EFUNC(voice,stepActive);
        true
    };
    default {false};
}
