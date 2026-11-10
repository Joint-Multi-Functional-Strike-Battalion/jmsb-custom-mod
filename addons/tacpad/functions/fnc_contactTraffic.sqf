#include "script_component.hpp"
/*
 * Author: YonV
 * What traffic says about the contact after a TIC (user, 2026-11-02: "after
 * contact a sitrep should be sent"). Run by messaging's onReceive hook with
 * the message that arrived, and on its quiet `indexRefreshed` event with
 * none - registered in XEH_postInit; nothing here polls.
 *
 * - HIS OWN TIC, back filed (the root of a card whose `broadcast` is
 *   CONTACT_BROADCAST): the watch starts on its thread (FUNC(contactArm)).
 * - HIS OWN SITREP, in the thread or as a thread of its own: the watch ends
 *   (FUNC(contactDrop)) - the SITREP the prompt asks for has been sent.
 * - A NEW TIC FROM HIS GROUP is contact again (FUNC(contactAgain)): one that
 *   reached him with its body, by its sender's group; one filed only on a net,
 *   which reaches him as an index row with no sender, when it is anchored
 *   within CONTACT_NEAR_M of one of his men.
 * - THE WATCHED THREAD CLOSED: the watch ends.
 *
 * Arguments:
 * 0: The message that arrived, empty for a quiet update <HASHMAP> (optional, default empty)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_message] call jmfsb_tacpad_fnc_contactTraffic
 *
 * Public: No
 */

params [["_message", createHashMap, [createHashMap]]];

if (isNil QEFUNC(messaging,template)) exitWith {};

private _fnc_isTic = {
    params ["_card"];
    (([_card] call EFUNC(messaging,template)) getOrDefault ["broadcast", ""]) isEqualTo CONTACT_BROADCAST
};

if (_message isNotEqualTo createHashMap) then {
    private _card = _message getOrDefault ["templateId", ""];
    private _root = (_message getOrDefault ["seq", -1]) isEqualTo 0;
    private _mine = (_message getOrDefault ["fromUid", ""]) isEqualTo getPlayerUID player;

    if (_mine) then {
        if (_root && {[_card] call _fnc_isTic}) then {
            [_message getOrDefault ["threadId", ""]] call FUNC(contactArm);
        } else {
            if (_card isEqualTo SITREP_CARD) then {[] call FUNC(contactDrop)};
        };
    } else {
        if (!_root || GVAR(contactThread) isEqualTo "") exitWith {};
        if ((_message getOrDefault ["fromGroup", ""]) isNotEqualTo groupId (group player)) exitWith {};
        if ([_card] call _fnc_isTic) then {[] call FUNC(contactAgain)};
    };
};

if (GVAR(contactThread) isEqualTo "") exitWith {};

// The index: the watched thread's state, and a TIC filed since near his group.
private _men = units group player;
private _closed = false;
private _again = false;
{
    if !(_x isEqualType createHashMap) then {continue};
    private _id = _x getOrDefault ["threadId", ""];
    if (_id isEqualTo GVAR(contactThread)) then {
        if ((_x getOrDefault ["status", ""]) in CONTACT_CLOSED) then {_closed = true};
        continue;
    };
    if (_id in GVAR(contactSeen)) then {continue};
    GVAR(contactSeen) pushBack _id;

    if !([_x getOrDefault ["templateId", ""]] call _fnc_isTic) then {continue};
    private _anchor = _x getOrDefault ["anchorPos", []];
    if !(_anchor isEqualType []) then {continue};
    if (count _anchor < 2) then {continue};
    if ((_men findIf {(_x distance2D _anchor) < CONTACT_NEAR_M}) >= 0) then {_again = true};
} forEach (missionNamespace getVariable [QEGVAR(messaging,index), []]);

if (_closed) exitWith {[] call FUNC(contactDrop)};
if (_again) then {[] call FUNC(contactAgain)};
