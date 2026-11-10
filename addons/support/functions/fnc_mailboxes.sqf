#include "script_component.hpp"
/*
 * Author: YonV
 * The support assets a message can be addressed to - the SUPPORT group of
 * TAC//MSG's TO picker (docs/DESIGN_SUPPORT_MESSAGING.md sections 3 and 6.1,
 * build step 2, 2026-11-01). One row per asset the viewer's side has
 * (FUNC(assets)) of a type MAILBOX_TYPES lists:
 *
 *   [boxId, callsign, type, word, state, can, why, eta, card, vehicle, takes]
 *
 *   boxId     "B:SUPPORT:<assetId>" - the box the server answers as the asset
 *             (README, "Threads"); a player crew's own "P:<uid>" (D8)
 *   callsign  the row's own name, what the box reads as (FUNC(boxName))
 *   type      the row's type key ("cas")
 *   word      the type as the row reads it ("CAS")
 *   state     IDLE, TASKED, ON STATION, RTB, REARMING or LOST - the row's status read
 *             through MAILBOX_STATES
 *   can       it can take a task at the sender's position now
 *   why       why not, "" when it can
 *   eta       seconds until it is over the sender, -1 unknown
 *   card      the deck card an @ mention of it opens in the composer
 *             (MAILBOX_TYPES), "" for none
 *   vehicle   a player crew's vehicle, its name; for a battery (a type
 *             MAILBOX_STOCK_TYPES lists) what it has left, briefly - "12 HE, 6
 *             SMOKE" (user, 2026-11-02); "" for any other asset
 *   takes     the deck cards it answers now (2026-11-02): its type's
 *             (MAILBOX_TYPES), REQUEST ON STATION alone while it must be asked
 *             on station first - a card the composer holds that is in here is
 *             kept on an @ mention (user, 2026-11-02: "on station is not a fire
 *             mission its just an order to get in the air")
 *
 * PLAYER CREWS ARE LISTED TOO (decision D8, user 2026-11-01): a man of the
 * viewer's side in a crew seat of a gun or an aircraft, under the type his
 * vehicle is (MAILBOX_PLAYER_*), after the assets - state PLAYER, no ETA,
 * his own player box. The thread goes to him; no provider acts on it.
 *
 * THE CARD IS THE TYPE'S (user, 2026-11-01: "need to have the proper template
 * also for the type of unit"), with one exception: an asset that must be asked
 * on station before it strikes (assets field 9 - a fixed-wing CAS aircraft the
 * AI flies) is mentioned with REQUEST ON STATION until its row reads ON
 * STATION, then with its type's card (doc 1.1). A helicopter, a drone and a
 * player-flown aircraft keep their type's card.
 *
 * CAN, WHY AND ETA ARE FUNC(reach) AT THE SENDER'S POSITION (decision D2:
 * state and ETA to the sender's grid). Without a position (no GPS fix) the row
 * can when its status is idle and has no ETA.
 *
 * A CARD THAT GOES TO SUPPORT NARROWS THE LIST to its types - a `cas` card
 * lists the CAS assets (6.1). Any other card, or none, lists every type
 * MAILBOX_TYPES has. The rows keep the order FUNC(assets) gives them, so a
 * list polled again does not reorder under the player's finger.
 *
 * NOT GATED HERE: who may see the group is the caller's question, asked once
 * when the picker opens - FUNC(canTask) says why in the RPT every time it
 * refuses, and this is polled. Asked when the picker opens and on its poll,
 * never per frame.
 *
 * Arguments:
 * 0: The sender's position, [x, y, z] ATL, [] for none <ARRAY>
 * 1: The card being written, "" for none <STRING> (optional, default "")
 *
 * Return Value:
 * 0: The card goes to support - the rows are its types only <BOOL>
 * 1: Rows <ARRAY>
 *
 * Example:
 * ([getPosATL player, "cas"] call jmfsb_support_fnc_mailboxes) params ["_forCard", "_rows"]
 *
 * Public: Yes
 */

params [["_pos", [], [[]]], ["_cardId", "", [""]]];

private _table = MAILBOX_TYPES;
private _types = _table apply {_x select 0};
private _forCard = _table select {_cardId in (_x select 2)};
private _matched = _forCard isNotEqualTo [];
if (_matched) then {
    _types = _forCard apply {_x select 0};
};

private _words = createHashMapFromArray (_table apply {[_x select 0, _x select 1]});
private _cards = createHashMapFromArray (_table apply {[_x select 0, _x param [3, ""]]});
private _takes = createHashMapFromArray (_table apply {[_x select 0, _x select 2]});
private _states = createHashMapFromArray MAILBOX_STATES;

private _reach = createHashMap;
if (count _pos >= 2) then {
    {
        _reach set [_x select 0, _x];
    } forEach ([_pos, _types] call FUNC(reach));
};

private _rows = [];
{
    _x params [["_id", "", [""]], ["_type", "", [""]], ["_callsign", "", [""]], "", ["_status", STATUS_IDLE, [""]]];
    if (_id isEqualTo "" || !(_type in _types)) then {continue};

    if (_callsign isEqualTo "") then {
        _callsign = toUpper _id;
    } else {
        GVAR(boxNames) set [_id, _callsign];
    };

    private _state = _states getOrDefault [toLower _status, MAILBOX_STATE_BUSY];

    (_reach getOrDefault [_id, []]) params [
        "",
        ["_can", _status isEqualTo STATUS_IDLE, [false]],
        ["_eta", ETA_UNKNOWN, [0]],
        ["_why", "", [""]]
    ];
    if (_can) then {
        _why = "";
    } else {
        if (_why isEqualTo "") then {_why = _state};
    };

    private _card = _cards getOrDefault [_type, ""];
    private _taken = +(_takes getOrDefault [_type, []]);
    if ((_x param [ROW_STATION_FIRST, false]) isEqualTo true && _state isNotEqualTo MAILBOX_STATE_STATION) then {
        _card = MAILBOX_CARD_STATION;
        _taken = [MAILBOX_CARD_STATION];
    };

    // A battery's stock, briefly (user, 2026-11-02): row field 9, which the
    // TO picker reads after the state.
    private _stock = "";
    if (_type in MAILBOX_STOCK_TYPES) then {
        private _ordnance = _x param [ROW_ORDNANCE, []];
        if !(_ordnance isEqualType []) then {_ordnance = []};
        _stock = ((_ordnance select [0, MAILBOX_STOCK_SHOWN]) apply {
            _x params [["_name", "", [""]], ["_left", 0, [0]]];
            format [MAILBOX_STOCK_ITEM, [str _left, MAILBOX_STOCK_UNLIMITED] select (_left < 0), _name]
        }) joinString MAILBOX_STOCK_SEP;
    };

    _rows pushBack [SUPPORT_BOX_PREFIX + _id, _callsign, _type, _words getOrDefault [_type, toUpper _type], _state, _can, _why, _eta, _card, _stock, _taken];
} forEach (call FUNC(assets));

// PLAYER CREWS, AFTER THE ASSETS (decision D8, user 2026-11-01): a man of the
// viewer's side in a crew seat - pilot, gunner, commander, a crew turret; not
// a passenger - of a gun or an aircraft, by the role that seat gives him: the
// type his vehicle is. His row is his own player box, so the thread reaches
// him and no provider acts on it; PLAYER, no ETA, and his vehicle's name.
{
    private _unit = _x;
    private _veh = vehicle _unit;
    if (_unit isEqualTo player || _veh isEqualTo _unit || !alive _unit) then {continue};
    if (_veh isKindOf "ParachuteBase") then {continue};

    private _crew = fullCrew _veh;
    private _seatAt = _crew findIf {(_x select 0) isEqualTo _unit};
    if (_seatAt < 0) then {continue};
    (_crew select _seatAt) params ["", ["_seat", "", [""]], "", "", ["_passenger", false, [false]]];
    if (_passenger || (toLower _seat) in MAILBOX_PLAYER_NOT_CREW) then {continue};

    private _cfg = configOf _veh;
    private _type = switch (true) do {
        case (getNumber (_cfg >> "artilleryScanner") > 0): {MAILBOX_PLAYER_GUN};
        case !(_veh isKindOf "Air"): {""};
        case (getNumber (_cfg >> "transportSoldier") > 0): {MAILBOX_PLAYER_LIFT};
        default {MAILBOX_PLAYER_AIR};
    };
    if (_type isEqualTo "" || !(_type in _types)) then {continue};

    _rows pushBack [
        MAILBOX_PLAYER_BOX + getPlayerUID _unit, toUpper (name _unit), _type, _words getOrDefault [_type, toUpper _type],
        MAILBOX_PLAYER_STATE, true, "", ETA_UNKNOWN, _cards getOrDefault [_type, ""],
        toUpper (getText (_cfg >> "displayName")),
        +(_takes getOrDefault [_type, []])
    ];
} forEach (allPlayers select {side group _x isEqualTo side group player});

[_matched, _rows]
