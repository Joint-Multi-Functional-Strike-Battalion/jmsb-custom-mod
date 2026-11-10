#include "script_component.hpp"
/*
 * Author: YonV
 * Server: what a CAS asset says and asks in its thread on the 2026-11-09 flow
 * (docs/DESIGN_MESSAGE_TEMPLATES.md, the message trees' tree 3) - one place
 * for the words, so this addon's drones and support_air's aircraft say the
 * same (as EFUNC(support,casPrompt) is for the older words):
 *
 *   "readback"        READBACK - TARGET <grid> - <restrictions> - CORRECT,
 *                     WRONG or FRAGO; values [target grid, restrictions]
 *   "sendfrago"       SEND FRAGO - after a WRONG; FRAGO or ABORT
 *   "fragolate"       ABORT FIRST - FRAGO NOT TAKEN AFTER IP INBOUND
 *   "ipinbound"       the `ipinbound` card - values [what it says, e.g. ETA]
 *   "in"              IN - <grid> - CLEARED HOT? (CLEARED HOT, CONTINUE,
 *                     ABORT; ALL ATTACK beside them for a fixed-wing flight
 *                     with escorts up) or, Type 3, IN - <grid> - CLEARED TO
 *                     ENGAGE? (CLEARED TO ENGAGE, ABORT); FLASH. values
 *                     [grid, control type, ALL ATTACK offered]
 *   "attackcomplete"  ATTACK COMPLETE - REQUEST BDA (after a Type 3 attack);
 *                     values [the escort drones' kills, -1 none]
 *   "intentions"      STATE INTENTIONS, with what it says first and the CAS
 *                     REQUEST among the answers (EFUNC(support,askIntentions));
 *                     values [what it says first]
 *   "line"            one line said in the thread (EFUNC(support,threadEvent));
 *                     values [the line]
 *
 * The questions go through EFUNC(support,prompt) with D9 (3 min NO RESPONSE -
 * HOLDING, 5 min the provider's own end).
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id <STRING>
 * 2: What - CAS_ASK_* <STRING>
 * 3: Its values <ARRAY>
 * 4: Call sign <STRING>
 * 5: No answer for PROMPT_END s, [assetId, threadId] <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["air:0", "T0042", "in", ["123456", 1, false], "HOG", {}] call jmfsb_cas_fnc_casAsk
 *
 * Public: Yes
 */

params [
    ["_assetId", "", [""]],
    ["_threadId", "", [""]],
    ["_what", "", [""]],
    ["_values", [], [[]]],
    ["_callsign", "", [""]],
    ["_onEnd", {}, [{}]]
];

if (!isServer || _assetId isEqualTo "" || _threadId isEqualTo "") exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_2("casAsk: refused - remote call from machine %1 (%2)",remoteExecutedOwner,_assetId);
};

private _fnc_ask = {
    params ["_text", "_answers", ["_flash", false]];
    [_assetId, _threadId, toUpper _text, _answers, _callsign, _onEnd, true, _flash] call EFUNC(support,prompt);
};

switch (_what) do {
    case CAS_ASK_READBACK: {
        _values params [["_grid", "", [""]], ["_restrictions", "", [""]]];
        private _said = [_restrictions select [0, CAS_READBACK_MAX], CAS_READBACK_NONE] select (_restrictions isEqualTo "");
        [format [CAS_READBACK_TEXT, _grid, _said], CAS_READBACK_ANSWERS] call _fnc_ask;
    };
    case CAS_ASK_SEND_FRAGO: {
        [CAS_SEND_FRAGO_TEXT, CAS_SEND_FRAGO_ANSWERS] call _fnc_ask;
    };
    case CAS_ASK_FRAGO_LATE: {
        [CAS_FRAGO_LATE_TEXT, CAS_FRAGO_LATE_ANSWERS, true] call _fnc_ask;
    };
    case CAS_ASK_IP_INBOUND: {
        _values params [["_text", "", [""]]];
        [_assetId, _threadId, CARD_IP_INBOUND, [[CARD_TEXT_KEY, toUpper _text]], _callsign] call EFUNC(support,fileCard);
    };
    case CAS_ASK_IN: {
        _values params [["_grid", "", [""]], ["_control", 0, [0]], ["_allAttack", false, [false]]];
        if (_control isEqualTo CAS_CONTROL_ENGAGE) exitWith {
            [format [CAS_IN_ENGAGE_TEXT, _grid], CAS_IN_ENGAGE_ANSWERS, true] call _fnc_ask;
        };
        [format [CAS_IN_HOT_TEXT, _grid], [CAS_IN_HOT_ANSWERS, CAS_IN_HOT_ANSWERS_FW] select _allAttack, true] call _fnc_ask;
    };
    case CAS_ASK_COMPLETE: {
        _values params [["_droneHits", -1, [0]]];
        [[CAS_COMPLETE_TEXT, format [CAS_COMPLETE_DRONES, _droneHits]] select (_droneHits >= 0), CAS_COMPLETE_ANSWERS] call _fnc_ask;
    };
    case CAS_ASK_INTENTIONS: {
        _values params [["_first", "", [""]]];
        [_assetId, _threadId, _callsign, toUpper _first, CAS_INTENTIONS_MORE, _onEnd] call EFUNC(support,askIntentions);
    };
    case CAS_ASK_LINE: {
        _values params [["_line", "", [""]]];
        [_assetId, _threadId, toUpper _line, false, _callsign] call EFUNC(support,threadEvent);
    };
    default {
        WARNING_2("casAsk: '%1' is not a CAS question (%2)",_what,_assetId);
    };
};
