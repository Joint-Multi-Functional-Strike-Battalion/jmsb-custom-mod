#include "script_component.hpp"
/*
 * Author: YonV
 * Who can reach one map point, how soon and with what - every asset the
 * viewer may task (FUNC(assets)) answered at once, best fit first
 * (docs/DESIGN_SUPPORT_V2.md section 6, 2026-11-01). TAC//MSG's TO picker
 * reads it at the sender's position (FUNC(mailboxes), decision D2).
 *
 *   [assetId, can, eta, why, effect, tasks]
 *
 *   can     the asset can service the point now
 *   eta     seconds until it does, -1 unknown
 *   why     a short reason when it cannot ("OUT OF RANGE 14/12 KM",
 *           "NO STORES", "TASKED"), "" when it can
 *   effect  one line for the card ("4 GUNS - HE 24 RDS")
 *   tasks   the task tokens valid at this point, [] when it cannot
 *
 * EACH PROVIDER ANSWERS FOR ITS OWN ASSETS through its "reach" code (README,
 * 2026-11-01). The core's reading for a provider without one served only the
 * ALiVE provider and went with it (user, 2026-11-02): no answer is NOT
 * AVAILABLE. The core's own cooldown ledger holds an asset whatever its
 * provider says, as FUNC(request) does.
 *
 * RANKED ETA ONLY (user, 2026-11-01, decision D5): an asset that can before
 * one that cannot, then the shortest ETA, an unknown ETA after every known
 * one, and FUNC(assets)' own list order last, so equal rows never swap between
 * asks. Matching the effect to the target comes after this is measured.
 *
 * Never asked per frame - but cheap anyway: one FUNC(assets) poll and
 * per-asset reads, no sweep of the map's units.
 *
 * Arguments:
 * 0: The point, [x, y, z] ATL <ARRAY>
 * 1: Asset types to answer for, [] for all <ARRAY of STRINGs> (optional, default [])
 *
 * Return Value:
 * Rows, best fit first <ARRAY>
 *
 * Example:
 * [screenToWorld [0.5, 0.5], ["arty"]] call jmfsb_support_fnc_reach
 *
 * Public: Yes
 */

params [["_pos", [], [[]]], ["_types", [], [[]]]];

if (count _pos < 2) exitWith {[]};

private _ledger = missionNamespace getVariable [QGVAR(readyAt), createHashMap];

private _rows = [];
private _keys = [];
{
    private _row = _x;
    _row params [["_id", "", [""]], ["_type", "", [""]]];
    if (_types isNotEqualTo [] && !(_type in _types)) then {continue};

    ([_id] call FUNC(provider)) params ["_kind", "_decl"];
    if (_kind isEqualTo "") then {continue};

    private _answer = [];
    if ("reach" in _decl) then {
        private _res = [_id, _pos] call (_decl get "reach");
        if (!isNil "_res" && {_res isEqualType []} && {count _res >= REACH_FIELDS}) then {_answer = _res};
    };
    _answer params [["_can", false, [false]], ["_eta", ETA_UNKNOWN, [0]], ["_why", "", [""]], ["_effect", "", [""]], ["_tasks", [], [[]]]];
    _tasks = _tasks select {_x isEqualType ""};

    // The core's ledger, as FUNC(request) reads it: a booked cooldown holds
    // the asset whatever its provider answers.
    private _readyAt = _ledger getOrDefault [_id, 0];
    if (_can && _readyAt > CBA_missionTime) then {
        _can = false;
        _why = format [REACH_WHY_COOLDOWN_FOR, ceil (_readyAt - CBA_missionTime)];
    };
    if (_can) then {_why = ""} else {
        _tasks = [];
        if (_why isEqualTo "") then {_why = REACH_WHY_NOT_AVAILABLE};
    };
    if (_eta < 0) then {_eta = ETA_UNKNOWN};

    // Sort keys: can first, a known ETA before an unknown one, the ETA, then
    // the list order - unique, so the sort never compares further.
    _keys pushBack [[1, 0] select _can, parseNumber (_eta < 0), _eta max 0, count _rows];
    _rows pushBack [_id, _can, _eta, _why, _effect, _tasks];
} forEach (call FUNC(assets));

_keys sort true;

_keys apply {_rows select (_x select 3)}
