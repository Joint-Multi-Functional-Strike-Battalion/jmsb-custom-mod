#include "script_component.hpp"
/*
 * Author: YonV
 * Server: what a CAS asset says and asks in the thread it strikes for
 * (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.1, 5.4 and step 5) - one place for
 * the words, so the drones and support_air's aircraft say the same:
 *
 *   "in"        IN - the run starts (the `in` card)
 *   "off"       after the release, on the way back to its station, one
 *               message (user, 2026-11-02): OFF - RETURNING TO STATION -
 *               REQUEST BDA - answer BDA (the `bda` card, its DECISION:
 *               RE-ATTACK or EGRESS), or a new CAS REQUEST in the thread;
 *               values [drones' kills] - after an ALL ATTACK, OFF -
 *               RETURNING TO STATION - DRONES DESTROYED <n> - REQUEST BDA
 *   "reattack"  the BDA said RE-ATTACK: RE-ATTACK - <n> <store> LEFT -
 *               AWAITING CLEARED HOT (FLASH) - CLEARED HOT, a new CAS
 *               REQUEST, or ABORT; values [rounds, store name, ALL ATTACK
 *               offered too - a fixed-wing flight with escorts up]
 *   "noescorts" ALL ATTACK with no escort up (user, 2026-11-02): NO ESCORTS -
 *               USE CLEARED HOT (FLASH) - CLEARED HOT or ABORT
 *   "tasking"   <n> MIN ON STATION - FURTHER TASKING? - a new `cas` card in
 *               the thread, RTB or CLOSE; values [minutes (-1: not known, the
 *               minutes are left out), why] - a reason a new card could not be
 *               flown goes in front
 *   "bingo"     BINGO IN 2 MIN - RTB or CLOSE, FLASH
 *
 * The questions go through FUNC(prompt) with D9 (3 min NO RESPONSE -
 * HOLDING, 5 min the provider's own end); the re-attack's wait for CLEARED HOT
 * and BINGO are FLASH here - the first AWAITING CLEARED HOT is
 * FUNC(promptCleared)'s. A deck without the `in` card says so in the RPT
 * (FUNC(srvFileCard)) and the rest goes on; the `off` card stays a player
 * pilot's.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id <STRING>
 * 2: What: "in", "off", "reattack", "noescorts", "tasking", "bingo" <STRING>
 * 3: Its values <ARRAY>
 * 4: Call sign <STRING>
 * 5: What the provider does after PROMPT_END s with no answer, [assetId, threadId] <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_assetId, _threadId, "reattack", [2, "GBU-12"], "HOG", {}] call jmfsb_support_fnc_casPrompt
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
// A provider's own call on the server, never a client's.
if (isRemoteExecuted) exitWith {
    WARNING_2("casPrompt: refused - remote call from machine %1 (%2)",remoteExecutedOwner,_assetId);
};

private _fnc_ask = {
    params ["_text", "_answers", ["_flash", false]];
    [_assetId, _threadId, _text, _answers, _callsign, _onEnd, true, _flash] call FUNC(prompt);
};

switch (_what) do {
    case CAS_IN: {
        [_assetId, _threadId, CARD_IN, [], _callsign] call FUNC(fileCard);
    };
    case CAS_OFF: {
        // One message (user, 2026-11-02): OFF - RETURNING TO STATION - REQUEST BDA;
        // after an ALL ATTACK what the escort drones destroyed with it.
        _values params [["_droneHits", -1, [0]]];
        [[PROMPT_BDA, format [PROMPT_BDA_DRONES, _droneHits]] select (_droneHits >= 0), ANSWERS_BDA] call _fnc_ask;
    };
    case CAS_REATTACK: {
        // A fixed-wing flight with escorts up is offered ALL ATTACK beside
        // CLEARED HOT (user, 2026-11-02).
        _values params [["_rounds", 0, [0]], ["_store", "", [""]], ["_allAttack", false, [false]]];
        [toUpper format [PROMPT_REATTACK, _rounds, _store], [ANSWERS_REATTACK, ANSWERS_REATTACK_FW] select _allAttack, true] call _fnc_ask;
    };
    case CAS_NO_ESCORTS: {
        // ALL ATTACK with no escort up (user, 2026-11-02): it asks again.
        [PROMPT_NO_ESCORTS, ANSWERS_AWAITING, true] call _fnc_ask;
    };
    case CAS_TASKING: {
        _values params [["_minutes", -1, [0]], ["_why", "", [""]]];
        private _text = [format [PROMPT_TASKING, floor _minutes], PROMPT_TASKING_ANY] select (_minutes < 0);
        if (_why isNotEqualTo "") then {_text = format [PROMPT_WHY, toUpper _why, _text]};
        [_text, ANSWERS_TASKING] call _fnc_ask;
    };
    case CAS_BINGO: {
        [PROMPT_BINGO, ANSWERS_BINGO, true] call _fnc_ask;
    };
    default {
        WARNING_2("casPrompt: '%1' is not a CAS prompt (%2)",_what,_assetId);
    };
};
