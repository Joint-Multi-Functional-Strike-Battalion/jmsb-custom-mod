#include "script_component.hpp"
/*
 * Author: JMSB
 * Every support asset the viewer can see, from every registered provider, as
 * the rows TAC//SUPPORT draws:
 *
 *   [id, type, callsign, platform, status, ordnance, guns, vehicle]
 *
 * See README.md for each field. A row whose id does not start with its
 * provider's kind is dropped - the kind is how a request finds its way back,
 * and a row that cannot be tasked is worse than no row. A provider "idle" row
 * that the core's cooldown ledger still holds is shown as "cooldown".
 *
 * Providers are walked in kind order so the merged list is stable between
 * polls (the screen redraws only when this changes).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Rows <ARRAY>
 *
 * Example:
 * call jmfsb_support_fnc_assets
 *
 * Public: Yes
 */

private _out = [];
private _ledger = missionNamespace getVariable [QGVAR(readyAt), createHashMap];
private _kinds = keys GVAR(providers);
_kinds sort true;

{
    private _kind = _x;
    private _rows = [] call ((GVAR(providers) get _kind) getOrDefault ["assets", {[]}]);
    if (isNil "_rows" || {!(_rows isEqualType [])}) then {continue};

    private _head = _kind + ID_SEP;
    {
        if (!(_x isEqualType []) || {!((_x param [0, ""]) isEqualType "")} || {((_x param [0, ""]) find _head) != 0}) then {
            if !(_kind in GVAR(badRowSaid)) then {
                GVAR(badRowSaid) pushBack _kind;
                WARNING_2("assets: provider '%1' listed a row whose id does not start with '%1:' - dropped (%2)",_kind,_x);
            };
            continue;
        };

        private _row = +_x;
        if ((_row param [4, STATUS_IDLE]) isEqualTo STATUS_IDLE && {(_ledger getOrDefault [_row select 0, 0]) > CBA_missionTime}) then {
            _row set [4, STATUS_COOLDOWN];
        };
        _out pushBack _row;
    } forEach _rows;
} forEach _kinds;

_out
