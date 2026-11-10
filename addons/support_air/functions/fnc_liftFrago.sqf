#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a FRAGO in a transport's thread (docs/DESIGN_MESSAGE_TEMPLATES.md,
 * 2026-11-09: "new LZ or new insertion method"; "new HLZ, station or
 * egress"; "patient count, precedence, LZ"). The support core hands over the
 * thread's current order with the FRAGO laid over it (EFUNC(support,
 * threadOrder)) and the FRAGO itself under "frago"; the job is planned again
 * from that, and nobody aboard is put out:
 *
 *   not lifted yet    the job is made again from the order (FUNC(liftJob)) -
 *                     the INSERTION after a PICKUP keeps its pickup - and
 *                     flown (FUNC(liftGo)) from where it is; a RED LZ asks
 *                     EXECUTE first, as a new one does. On the deck at its
 *                     pickup it stays there and the troop load is asked
 *                     again
 *   lifted, an        on its way to the LZ with the stick: the LZ leg
 *   insertion         written again - the new LZ, its route, its method
 *                     (ropes or land), its approach
 *   lifted, an        loaded: home by the new egress
 *   extraction
 *   anything else     the change is noted - FRAGO - NO CHANGE TO FLY
 *
 * It says FRAGO - <the lines changed> (the FRAGO's own changed lines,
 * EFUNC(messaging,fragoLines)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Thread <HASHMAP>
 * 2: The merged order message <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _thread, _message] call jmfsb_support_air_fnc_liftFrago
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_thread", createHashMap, [createHashMap]], ["_message", createHashMap, [createHashMap]]];

if (!isServer || {isNull _logic}) exitWith {};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if (count _job isEqualTo 0) exitWith {};
private _threadId = _job get "thread";
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _issuer = _job get "issuer";

// What changed, as the FRAGO's own lines say.
private _frago = _message getOrDefault ["frago", createHashMap];
private _changed = ([_frago getOrDefault ["payload", []]] call EFUNC(messaging,fragoLines)) apply {toUpper (_x select 0)};
private _what = [_changed joinString ", ", toUpper (_message getOrDefault ["templateId", ""])] select (_changed isEqualTo []);

private _order = [_thread, _message] call EFUNC(support,readOrder);
private _kind = _order getOrDefault ["kind", ""];
private _lifted = _job getOrDefault ["lifted", false];

// --- lifted: only the legs still ahead ----------------------------------------
if (_lifted) exitWith {
    if (_kind isEqualTo ORDER_LIFT && {(_job get "kind") isEqualTo ORDER_LIFT} && {(_order getOrDefault ["lz", []]) isNotEqualTo []}) exitWith {
        private _next = [_logic, _order, _issuer, _threadId, TASK_LIFT, _job get "first"] call FUNC(liftJob);
        {_next set [_x, _job getOrDefault [_x, _next get _x]]} forEach ["legs", "leg", "down", "onDeck", "lifted"];
        _logic setVariable [QGVAR(liftJob), _next];
        private _insert = _next get "insertTask";
        if (_insert isEqualTo TASK_FASTROPE && {!([typeOf _veh] call FUNC(canRope))}) then {_insert = TASK_RAPPEL};
        private _approach = _next getOrDefault ["approach", -1];
        [_logic, _insert, _next get "lz", _next get "lzVia", LZ_HOLD_ORBIT, _approach] call FUNC(liftOrder);
        [_logic] call FUNC(liftZones);
        [_logic, _threadId, format [SAID_WILCO, format [SAID_FRAGO, _what]]] call FUNC(liftSay);
    };
    if (_kind isEqualTo ORDER_EXTRACT && {(_job get "kind") isEqualTo ORDER_EXTRACT}) exitWith {
        private _egress = _order getOrDefault ["egressRoute", []];
        ((_logic getVariable [QGVAR(order), []]) param [7, createHashMap]) set ["via", +_egress];
        _job set ["lzVia", _egress];
        [_logic, _threadId, format [SAID_WILCO, format [SAID_FRAGO, _what]]] call FUNC(liftSay);
    };
    [_logic, _threadId, SAID_FRAGO_NONE] call FUNC(liftSay);
};

// --- not lifted: the job again ------------------------------------------------
private _task = "";
private _first = [];
private _why = "";
if (_kind isEqualTo ORDER_LIFT && {(_job get "kind") in [ORDER_PICKUP, ORDER_LIFT]}) then {
    // The INSERTION keeps the pickup it was given (filed after a PICKUP, or
    // the sender's) - only its LZ is the FRAGO's.
    _task = TASK_LIFT;
    _first = _job get "first";
    if ((_order getOrDefault ["lz", []]) isEqualTo []) then {_why = WHY_NO_TARGET};
} else {
    ([_logic, _order, _issuer] call FUNC(liftLegs)) params ["_legTask", "_legFirst", "_legWhy"];
    _task = _legTask;
    _first = _legFirst;
    _why = _legWhy;
};
if (_why isNotEqualTo "") exitWith {
    [_logic, _threadId, format ["%1 - %2", format [SAID_FRAGO, _what], _why]] call FUNC(liftSay);
};

private _next = [_logic, _order, _issuer, _threadId, _task, _first] call FUNC(liftJob);
{_next set [_x, _job getOrDefault [_x, _next get _x]]} forEach ["legs", "leg", "down", "onDeck"];
private _hot = (_order getOrDefault ["security", ""]) isEqualTo LZ_RED;
_logic setVariable [QGVAR(liftJob), _next];
[_logic] call FUNC(liftZones);
[_logic, _threadId, format [SAID_WILCO, format [SAID_FRAGO, _what]]] call FUNC(liftSay);

// On the deck at its pickup with the same pickup: it stays, the troop load
// asked again - a RED LZ confirmed first (FUNC(liftLoad)).
if ((_next getOrDefault ["onDeck", false]) && {_first isEqualTo (_job get "first")} && _task isEqualTo TASK_LIFT) exitWith {
    _next set ["hotPending", _hot];
    _next set ["lifted", false];
    [_logic] call FUNC(liftLoad);
};
_next set ["onDeck", false];
if (_hot) exitWith {
    _next set ["step", JOB_CONFIRM];
    [_logic, _threadId, PROMPT_HOT, ANSWERS_HOT] call FUNC(threadPrompt);
};
[_logic] call FUNC(liftGo);
