#include "script_component.hpp"
/*
 * Author: YonV
 * Works out which thread a submission belongs to and whether the sender is
 * allowed to put it there - opening a new thread when there is no thread id,
 * checking the reply rules when there is.
 *
 * This is its own function rather than a branch inside srvSubmit because every
 * check here wants to stop the rest of them, and exitWith inside an if/then
 * block exits the block, not the function. Split out, each refusal is a plain
 * early return and cannot silently fall through to the next check.
 *
 * Arguments:
 * 0: Sending player <OBJECT>
 * 1: Template <HASHMAP>
 * 2: Payload <ARRAY>
 * 3: Thread id, "" to open a new one <STRING>
 *
 * Return Value:
 * 0: Thread <HASHMAP>, empty when refused
 * 1: Why not, "" when accepted <STRING>
 * 2: This opened the thread <BOOL>
 *
 * Example:
 * ([_unit, _template, _payload, ""] call jmfsb_messaging_fnc_srvThreadFor) params ["_thread", "_why", "_isRoot"]
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_template", createHashMap, [createHashMap]],
    ["_payload", [], [[]]],
    ["_threadId", "", [""]],
    // An explicit pin from the composer. It beats the template's own anchor,
    // because it is the one the sender chose on purpose.
    ["_pin", [], [[]]]
];

private _uid = getPlayerUID _unit;
private _templateId = _template get "id";
private _transition = _template get "transitionsTo";

if (_threadId == "") exitWith {
    if ((_template get "kind") == "reply") exitWith {
        [createHashMap, "that template is a reply, it cannot start a thread", false]
    };

    // The anchor is snapshotted now. A marker the sender used may be deleted an
    // hour later; where they said the contact was does not change.
    private _anchorPos = [];

    // THE PIN WINS. A plain message has no field to anchor on, so the composer
    // sends the position beside the payload; when one is there it is deliberate,
    // and it beats whatever the template would have anchored on.
    //
    // ONLY A PIN DRAWS A MARKER. Every thread has had an anchorPos since the
    // beginning - it is what the map view flies to - so marking them all would
    // wallpaper the map with every SITREP ever filed. "pinned" is set here and
    // FUNC(srvDeliver) is what reads it; a template anchor still only anchors.
    private _pinned = false;
    if (count _pin >= 2) then {
        _anchorPos = [_pin # 0, _pin # 1, 0];
        _pinned = true;
    };

    // A TYPED GRID ANCHORS TOO (report-card review, 2026-11-02, rule 9). Only
    // a position from a map click or CUR LOC did, so a grid typed by hand put
    // the thread's anchor on the sender while the support pin, which reads the
    // grid, was right. FUNC(fieldPos) reads a position, a marker name or a
    // typed grid alike.
    private _anchorKey = _template get "anchor";
    if (_anchorPos isEqualTo [] && _anchorKey != "") then {
        private _raw = (createHashMapFromArray _payload) getOrDefault [_anchorKey, []];
        if (_raw isEqualTypeAny [[], ""]) then {
            _anchorPos = [_raw] call FUNC(fieldPos);
        };
    };
    if (_anchorPos isEqualTo []) then {
        _anchorPos = getPosATL _unit;
    };

    private _id = ["T"] call FUNC(srvNextId);

    private _thread = createHashMapFromArray [
        ["id", _id],
        // A task is a thread whose root template moves it into a state. There
        // is no separate task object, so nothing can disagree about whether a
        // given report is one.
        ["kind", ["message", "task"] select (_transition != "")],
        ["subject", [_templateId, _payload] call FUNC(subject)],
        ["rootTemplateId", _templateId],
        ["status", ["OPEN", _transition] select (_transition != "")],
        ["priority", _template get "priority"],
        ["issuerUid", _uid],
        ["claimedBy", ""],
        ["participants", [_uid]],
        ["boxes", []],
        // THE ONE BOX THE THREAD LIVES IN, decided by FUNC(srvDeliver) when the
        // root is filed and never changed after. "boxes" is everywhere it was
        // COPIED to; this is where it IS. Every index row for this thread -
        // the sender's, a reader's, a reconnecting player's - carries this box,
        // so the whole net agrees about which net a conversation is on.
        ["box", ""],
        // Every audience tag anybody has put on this conversation. Appended to
        // by FUNC(srvSubmit) as it goes on.
        ["tags", []],
        ["anchorPos", _anchorPos],
        ["pinned", _pinned],
        ["anchorLabel", mapGridPosition _anchorPos],
        ["parentThreadId", ""],
        ["lastActivity", CBA_missionTime],
        ["closed", false],
        ["messages", []]
    ];

    GVAR(threads) set [_id, _thread];
    [_thread, "", true]
};

private _thread = GVAR(threads) getOrDefault [_threadId, createHashMap];
if (_thread isEqualTo createHashMap) exitWith {[createHashMap, "that thread no longer exists", false]};
if (_thread get "closed") exitWith {[createHashMap, "that thread is closed", false]};

// Reading a thread and adding to it are different rights. A player may read
// anything filed to a shared mailbox; only a participant or somebody the thread
// was filed to may reply into it.
private _visible = [_unit] call FUNC(srvBoxesFor);
private _addressed = (_thread get "boxes") findIf {_x in _visible} >= 0;
if !(_uid in (_thread get "participants") || _addressed) exitWith {
    [createHashMap, "that thread is not addressed to you", false]
};

// THE THREAD'S OWNER RULES FIRST (FUNC(onThreadCard), 2026-11-02): a hook
// may take a ROOT card into a thread it owns (a support asset's re-task, its
// NEXT LIFT) or refuse a card that is not the sender's to send (the asset's
// WILCO or ON TASK from the man who asked for it). A player's card only - the
// server's own filings (an asset's states, through the call sign override)
// are not put to the hooks.
private _own = [] call EFUNC(common,fromServer);
private _ruling = "";
if (!_own) then {
    {
        private _said = [_thread, _template, _unit] call _x;
        if (isNil "_said") then {_said = ""};
        if !(_said isEqualType "") then {_said = ""};
        if (_said isNotEqualTo "") exitWith {_ruling = _said};
    } forEach (localNamespace getVariable [QGVAR(threadCardHooks), []]);
};
if (_ruling isNotEqualTo "" && _ruling isNotEqualTo THREAD_CARD_TAKE) exitWith {
    [createHashMap, _ruling, false]
};
// A ROOT CARD OPENS A THREAD. Until 2026-11-02 any root card went into any
// thread a client named; now only one a hook takes, or the server's own.
if (!_own && (_template get "kind") isEqualTo KIND_ROOT && _ruling isNotEqualTo THREAD_CARD_TAKE) exitWith {
    [createHashMap, format ["%1 opens its own thread", _template get "short"], false]
};

private _allowed = _template get "allowedFrom";
if (_allowed isNotEqualTo [] && {!((_thread get "status") in _allowed)}) exitWith {
    [createHashMap, format ["%1 is not allowed while the thread is %2", _template get "short", _thread get "status"], false]
};

private _mustBe = _template get "senderMustBe";
private _satisfied = switch (_mustBe) do {
    case "issuer": {_uid == (_thread get "issuerUid")};
    // Nobody has claimed it yet, so anyone it reached may answer. Refusing
    // every reply until somebody claims deadlocks a task nobody can claim.
    case "assignee": {(_thread get "claimedBy") in ["", _uid]};
    case "boxMember": {_addressed};
    // The mission's own flag - the one a lead's role sets (isLeader) and the
    // one every tag rule already reads. METT-TC is the only template that
    // asks for it: an estimate is a leader's to give.
    case "leader": {(_unit getVariable ["isLeader", false]) isEqualTo true};
    default {true};
};
if (!_satisfied) exitWith {
    [createHashMap, format ["only the %1 may send that", _mustBe], false]
};

(_thread get "participants") pushBackUnique _uid;

[_thread, "", false]
