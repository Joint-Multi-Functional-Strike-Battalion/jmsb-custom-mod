#include "script_component.hpp"
/*
 * Author: YonV
 * Client poll, every PIN_POLL s (XEH_postInit): the support threads' map pins
 * (2026-11-01, DESIGN_SUPPORT_MESSAGING 6.3, build step 8 - "for support
 * threads the pin also draws: target / LZ marker, danger-close ring,
 * ingress/egress lines from the template, and while in progress the impact
 * ring (fires) or route (transport) from the provider's overlay").
 *
 * 1. A support thread in the index that this player opened (messaging's cache)
 *    and holds no card for yet: its newest support card is held
 *    (FUNC(pinRoot)); traffic pushed to him is held as it arrives.
 * 2. A held thread that is over (CLOSED, DECLINED, ABORTED) or gone from the
 *    index lets go of its card, and its shapes are removed. The plain pin a
 *    thread carries (messaging's cltMarker) is not this function's and stays,
 *    as it does for every thread.
 * 3. Each held thread: its card's shapes (FUNC(pinCard)) and, IN_PROGRESS, its
 *    asset's (FUNC(pinLive)). Only a marker whose spec changed is drawn again
 *    (FUNC(pinMarker)); one no longer wanted is removed.
 *
 * Never per frame. The asset rows are asked only while a thread is IN_PROGRESS,
 * the friendlies only while a card has a danger-close distance.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_support_fnc_pinTick
 *
 * Public: No
 */

if (!hasInterface) exitWith {};

private _index = missionNamespace getVariable [QEGVAR(messaging,index), []];
private _cache = missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap];
private _head = count SUPPORT_BOX_PREFIX;

// --- 1. the index: each thread's status, and the opened threads' cards -------
private _status = createHashMap;
{
    if !(_x isEqualType createHashMap) then {continue};
    private _threadId = _x getOrDefault ["threadId", ""];
    private _state = _x getOrDefault ["status", ""];
    _status set [_threadId, _state];
    if (_state in STATES_OVER) then {continue};
    if (_threadId in GVAR(pinRoots)) then {continue};
    if !(_threadId in _cache) then {continue};

    private _box = _x getOrDefault ["boxId", ""];
    if !(_box isEqualType "") then {_box = ""};
    if ((toUpper (_box select [0, _head])) isNotEqualTo SUPPORT_BOX_PREFIX && !((_x getOrDefault ["templateId", ""]) in PIN_CARDS)) then {continue};

    (_cache get _threadId) params [["_thread", createHashMap, [createHashMap]], ["_messages", [], [[]]]];
    private _cards = _messages select {_x isEqualType createHashMap && {(_x getOrDefault ["templateId", ""]) in PIN_CARDS}};
    private _card = _messages param [0, createHashMap];
    if (_cards isNotEqualTo []) then {_card = _cards select -1};
    [_threadId, _card, (_thread getOrDefault ["boxes", []]) + [_box]] call FUNC(pinRoot);
} forEach _index;

// --- 2. what is over, or gone ---------------------------------------------
private _over = (keys GVAR(pinRoots)) select {(_status getOrDefault [_x, ""]) in (STATES_OVER + [""])};
{GVAR(pinRoots) deleteAt _x} forEach _over;

private _dropped = (keys GVAR(pinDrawn)) select {!(_x in GVAR(pinRoots))};
{
    {deleteMarkerLocal _x} forEach (keys (GVAR(pinDrawn) get _x));
    GVAR(pinDrawn) deleteAt _x;
} forEach _dropped;

if (count GVAR(pinRoots) isEqualTo 0) exitWith {};

// --- 3. draw ----------------------------------------------------------------
private _rows = [];
if ((keys GVAR(pinRoots)) findIf {(_status getOrDefault [_x, ""]) isEqualTo STATE_IN_PROGRESS} >= 0) then {
    _rows = call FUNC(assets);
};

// The friendlies the blue force tracker shows the player's side, else the
// side's players.
private _friends = [];
if ((values GVAR(pinRoots)) findIf {((_x select 0) getOrDefault ["dangerClose", 0]) isNotEqualTo 0} >= 0) then {
    if (isNil QEFUNC(bft,friendlies)) then {
        private _side = side group (call CBA_fnc_currentUnit);
        _friends = allPlayers select {alive _x && (side group _x) isEqualTo _side};
    } else {
        _friends = [] call EFUNC(bft,friendlies);
    };
};

{
    private _threadId = _x;
    _y params ["_order", "_assetId"];
    private _callsign = "";
    if (_assetId isNotEqualTo "") then {_callsign = [SUPPORT_BOX_PREFIX + _assetId] call FUNC(boxName)};

    private _specs = [_order, _callsign, _friends] call FUNC(pinCard);
    if ((_status getOrDefault [_threadId, ""]) isEqualTo STATE_IN_PROGRESS) then {
        private _at = _rows findIf {(_x param [0, ""]) isEqualTo _assetId};
        private _row = [];
        if (_at >= 0) then {_row = _rows select _at};
        _specs append ([_assetId, _row, _callsign] call FUNC(pinLive));
    };

    private _base = format [QGVAR(pin_%1), _threadId];
    private _old = GVAR(pinDrawn) getOrDefault [_threadId, createHashMap];
    private _new = createHashMap;
    {_new set [format ["%1_%2", _base, _forEachIndex], _x]} forEach _specs;
    {
        if !(_x in _new) then {deleteMarkerLocal _x};
    } forEach (keys _old);
    {
        if ((_old getOrDefault [_x, []]) isNotEqualTo (_new get _x)) then {[_x, _new get _x] call FUNC(pinMarker)};
    } forEach (keys _new);
    GVAR(pinDrawn) set [_threadId, _new];
} forEach GVAR(pinRoots);
