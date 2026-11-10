#include "script_component.hpp"
/*
 * Author: YonV
 * Accepts or refuses a submitted message. This is the only function that writes
 * a message into the store, so every rule about who may say what runs here or
 * in srvThreadFor, and nowhere else. The client validated first as a courtesy
 * to the player; this is the validation that decides.
 *
 * A client sends it by remoteExecCall to the server (FUNC(submit)). The unit
 * handed in must be the sending machine's own (review S7: a CBA event carries
 * no sender, so anyone could file as anyone), checked at the top before
 * anything else. The server's own calls - the counter-battery radar, the msg.*
 * test commands - pass as the server's.
 *
 * Arguments:
 * 0: Sending player <OBJECT>
 * 1: Draft nonce, one per press of send <STRING>
 * 2: Template id <STRING>
 * 3: Payload <ARRAY> - [fieldKey, value] pairs
 * 4: Addressees <ARRAY> - mailbox ids or bare names
 * 5: Thread to reply in, "" to open a new one <STRING>
 * 6: Message being replied to, "" for the thread root <STRING>
 * 7: File it under another call sign, "" to use the sender's <STRING>
 * 8: Audience tags <ARRAY> of <STRING>
 * 9: Map pin, [x, y, z] for a thread that should mark the map, [] for none <ARRAY>
 * 10: Priority, "" for the template's own - the server's own call only <STRING> (optional, default "")
 *
 * THE CALL SIGN OVERRIDE IS FOR TESTING ALONE, and it is here rather than in a
 * second write path because a test that files messages through code the live
 * system does not use proves nothing about the live system. A message filed
 * under another call sign is also NOT pre-read by the sender, so it arrives
 * unread with a notification - which is the half of the system a man testing on
 * his own can otherwise never see. See the msg.* admin commands. Only the
 * server and an admin by the server's records may use it (review S7); from
 * anyone else it is dropped and the message is filed under his own call sign.
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _nonce, "freetext", [["Text.A", "hello"]], ["B:HQ"], "", "", "", [], []] remoteExecCall ["jmfsb_messaging_fnc_srvSubmit", 2]
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_nonce", "", [""]],
    ["_templateId", "", [""]],
    ["_payload", [], [[]]],
    ["_addressees", [], [[]]],
    ["_threadId", "", [""]],
    ["_parentId", "", [""]],
    ["_asCallsign", "", [""]],
    ["_tags", [], [[]]],
    ["_pin", [], [[]]],
    ["_priorityOverride", "", [""]]
];

if (!isServer) exitWith {};
// WHO SENT IT, from the engine (review S7) - before anything else reads _unit.
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_2("srvSubmit: refused - machine %1 tried to file as %2",remoteExecutedOwner,_unit);
};
if (_asCallsign isNotEqualTo "" && {!([] call EFUNC(common,senderIsAdmin))}) then {
    WARNING_2("srvSubmit: call sign '%1' from machine %2 dropped - not an admin",_asCallsign,remoteExecutedOwner);
    _asCallsign = "";
};

// The client tidies these, but the client is not who decides. A tag that
// arrives as a number or an empty string would go on to be asked of every
// player on the server once per delivery.
_tags = (_tags select {_x isEqualType ""}) apply {toUpper (trim _x)};
_tags = _tags select {_x isNotEqualTo ""};
if (count _tags > TAG_MAX) then {_tags resize TAG_MAX};

if (!GVAR(enabled)) exitWith {};
if (!isPlayer _unit || {!alive _unit}) exitWith {};

// The nonce is what makes a double-click harmless: a repeat is dropped rather
// than filed as a second CASEVAC.
if (_nonce == "" || {_nonce in GVAR(nonces)}) exitWith {};
GVAR(nonces) set [_nonce, CBA_missionTime];

private _uid = getPlayerUID _unit;

private _fnc_refuse = {
    params ["_why"];
    [_templateId, _why] remoteExecCall [QFUNC(cltReject), _unit];
    INFO_3("refused '%1' from %2 - %3",_templateId,_uid,_why);
};

private _template = [_templateId] call FUNC(template);
if (_template isEqualTo createHashMap) exitWith {["no such template"] call _fnc_refuse};

([_templateId, _payload] call FUNC(validate)) params ["_ok", "_why"];
if (!_ok) exitWith {[_why] call _fnc_refuse};

([_unit, _template, _payload, _threadId, _pin] call FUNC(srvThreadFor)) params ["_thread", "_threadWhy", "_isRoot"];
if (_threadWhy != "") exitWith {[_threadWhy] call _fnc_refuse};

if (_isRoot && {_addressees isEqualTo []}) exitWith {
    GVAR(threads) deleteAt (_thread get "id");
    ["no addressee"] call _fnc_refuse
};

// A FRAGO (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09) changes the thread's
// current order (FUNC(currentOrder)): the card it names must be that order,
// something must change, and the order with the changes laid over it must
// pass that card's own checks. The old values are the server's, not the
// client's: each changed key's FRAGO_WAS is written here.
if (_templateId isEqualTo FRAGO_ID) then {
    private _bodies = (_thread get "messages") apply {GVAR(messages) getOrDefault [_x, createHashMap]};
    ([_bodies] call FUNC(currentOrder)) params ["_orderId", "_orderPayload"];
    private _frago = createHashMapFromArray _payload;
    private _named = _frago getOrDefault [FRAGO_CARD_KEY, ""];
    if (_orderId isEqualTo "") exitWith {_threadWhy = FRAGO_NO_ORDER};
    if (_named isNotEqualTo _orderId) exitWith {_threadWhy = format [FRAGO_WRONG_ORDER, _named]};
    private _was = createHashMapFromArray _orderPayload;
    private _merged = +_was;
    private _changes = createHashMap;
    {
        if (_x in [FRAGO_CARD_KEY, FRAGO_REASON_KEY] || {(_x find FRAGO_WAS) >= 0}) then {continue};
        if (_y isEqualTo (_was getOrDefault [_x, ""])) then {continue};
        _changes set [_x, _y];
        if (_y in ["", false]) then {_merged deleteAt _x} else {_merged set [_x, _y]};
    } forEach _frago;
    if (count _changes isEqualTo 0) exitWith {_threadWhy = FRAGO_NOTHING};
    ([_orderId, _merged toArray false] call FUNC(validate)) params ["_mergedOk", "_mergedWhy"];
    if (!_mergedOk) exitWith {_threadWhy = format ["FRAGO - %1", _mergedWhy]};
    private _clean = [[FRAGO_CARD_KEY, _orderId]];
    private _reason = _frago getOrDefault [FRAGO_REASON_KEY, ""];
    if (_reason isNotEqualTo "") then {_clean pushBack [FRAGO_REASON_KEY, _reason]};
    {
        _clean pushBack [_x, _y];
        _clean pushBack [_x + FRAGO_WAS, _was getOrDefault [_x, ""]];
    } forEach _changes;
    _payload = _clean;
};
if (_threadWhy != "") exitWith {[_threadWhy] call _fnc_refuse};

private _priority = _template get "priority";
// A PRIORITY OF THE SERVER'S OWN (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4): a
// support asset's `prompt` is FLASH only while it waits to release or is about
// to leave - one card, two urgencies. Only the server's own call sets it; from
// a client it is dropped.
if (_priorityOverride in PRIORITY_OVERRIDES && !isRemoteExecuted) then {
    _priority = _priorityOverride;
};
private _transition = _template get "transitionsTo";
private _messageId = ["M"] call FUNC(srvNextId);

private _message = createHashMapFromArray [
    ["id", _messageId],
    // Ordering is the sequence a thread was written in, never the clock. Two
    // messages a frame apart have the same time and would sort at random.
    ["seq", count (_thread get "messages")],
    ["threadId", _thread get "id"],
    ["parentId", _parentId],
    ["fromUid", _uid],
    ["fromCallsign", [format ["%1 %2", groupId (group _unit), name _unit], _asCallsign] select (_asCallsign isNotEqualTo "")],
    // THE TAGS, STAMPED AT SEND TIME. Squad, job and urgency travel WITH the
    // message rather than being looked up when it is read: a man who was the
    // medic in ALPHA when he sent a CASEVAC is still that when it is read an
    // hour later, after he has been promoted and cross-posted. A tag worked out
    // at read time is a tag that lies about old traffic.
    //
    // Urgency is the template's own priority - see FUNC(registerTemplate) - so a
    // CASEVAC is FLASH because it is a CASEVAC, not because somebody ticked it.
    ["fromGroup", groupId (group _unit)],
    ["fromRole", [_unit] call FUNC(roleTag)],
    // WHO WAS CALLED OUT BY NAME. These travel with the message so the reader
    // can show them and so a client can tell it was one of the people meant -
    // see FUNC(cltReceive), which raises its own alert off exactly this.
    ["tags", _tags],
    ["templateId", _templateId],
    ["payload", _payload],
    ["sentTime", CBA_missionTime],
    ["gameTime", date],
    ["priority", _priority],
    ["transition", _transition],
    // A man has read what he just wrote. One filed under somebody else's call
    // sign he has not - so it arrives unread, with a notification, like traffic.
    ["readBy", [[_uid], []] select (_asCallsign isNotEqualTo "")]
];

GVAR(messages) set [_messageId, _message];
(_thread get "messages") pushBack _messageId;
_thread set ["lastActivity", CBA_missionTime];

// The thread carries every tag anybody has put on it, not just the root's. Tag
// a squad into a conversation halfway down and they stay in it - being called
// for once is not a thing that expires when the next message arrives.
private _threadTags = _thread getOrDefault ["tags", []];
{_threadTags pushBackUnique _x} forEach _tags;
_thread set ["tags", _threadTags];

if (_priority == "high") then {
    _thread set ["priority", "high"];
};

// A root template's transition is the thread's opening state and was applied
// when the thread was made; a reply's transition moves it.
// A STARTER FILED INTO AN OPEN THREAD (2026-11-09) - the asset's next tasking,
// or a support request filed in a TIC, SALUTE or MIST - makes it a task
// thread: the thread's kind is what says a task is in it.
if (!_isRoot && _transition != "" && {(_template get "kind") in [KIND_ROOT, KIND_BOTH]}) then {
    _thread set ["kind", "task"];
};
if (!_isRoot && _transition != "") then {
    _thread set ["status", _transition];
    if (_transition in ["CLOSED", "ABORTED"]) then {
        _thread set ["closed", true];
    };
};

[_unit, _thread, _message, _addressees] call FUNC(srvDeliver);

if ((_template get "reportable") != "") then {
};

if ((_template get "broadcast") == "tic") then {
    [_unit, _thread, _payload] call FUNC(srvTic);
};

// THE FILED HOOKS (FUNC(onFiled), user 2026-11-01) - the support core answers
// a thread filed to an asset's box from one of these. Last, after the message
// is stored, boxed and pushed, and each in the next frame on its own: a hook
// that errors cannot take the filing with it, and it runs outside this
// client's remoteExecCall, so a reply it files is the server's. The box list
// is a copy; the thread and message are the store's own records.
private _boxIds = +(_thread get "boxes");
{
    [_x, [_thread, _message, _boxIds]] call CBA_fnc_execNextFrame;
} forEach (localNamespace getVariable [QGVAR(filedHooks), []]);
