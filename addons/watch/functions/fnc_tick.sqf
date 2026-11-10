#include "script_component.hpp"
/*
 * Author: YonV
 * Once a second on the player's machine: the auto-clear (when his setting has
 * it on), the profiles' own keep rule, the self-aid slot, the contacts' map
 * tracks and the engineer's eye.
 *
 * A target that is gone or dead comes off; one past LOST_RANGE for
 * LOST_SECONDS comes off; a pinned slot stays whatever happens, unless its
 * target no longer exists. A profile with a keep rule (recon: the server still
 * holds the contact) drops a slot that fails it, KEEP_GRACE seconds after it
 * was added. Each removal runs the profile's onRemove.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_watch_fnc_tick
 *
 * Public: No
 */

{
    private _id = _x;
    private _spec = GVAR(profiles) getOrDefault [_id, createHashMap];
    private _keepCode = _spec getOrDefault ["keep", {true}];
    private _keep = [];
    private _gone = [];
    {
        _x params ["_target", "_pinned", "_lostSince", ["_added", 0]];
        if (isNull _target) then {continue};
        private _stay = switch (true) do {
            case ((CBA_missionTime - _added) > KEEP_GRACE && {!([_target] call _keepCode)}): {false};
            case (_pinned || {!GVAR(autoClear)}): {true};
            case (!alive _target): {false};
            case ((player distance _target) > LOST_RANGE): {
                if (_lostSince < 0) then {_x set [2, CBA_missionTime]};
                (CBA_missionTime - (_x # 2)) <= LOST_SECONDS
            };
            default {_x set [2, -1]; true};
        };
        [_gone, _keep] select _stay pushBack _x;
    } forEach _y;
    GVAR(slots) set [_id, _keep];
    private _onRemove = _spec getOrDefault ["onRemove", {}];
    {[_x # 0] call _onRemove} forEach _gone;

    // ALERTS (design core.notifications): a profile's alert code says what
    // holds now; one that was not holding a second ago goes through the
    // existing notification row - "MEDICAL 2: SMITH - TQ OVER 10 MIN".
    private _alertCode = _spec getOrDefault ["alert", {}];
    if (_alertCode isEqualTo {}) then {continue};
    private _row = _spec getOrDefault ["row", {[]}];
    {
        private _now = [_x # 0] call _alertCode;
        if (isNil "_now" || {!(_now isEqualType [])}) then {_now = []};
        private _new = _now - (_x param [4, []]);
        _x set [4, _now];
        if (_new isEqualTo []) then {continue};
        [NOTE_TITLE, format ["%1 %2: %3 - %4", toUpper (_spec getOrDefault ["name", _id]), _forEachIndex + 1,
            ([_x # 0] call _row) param [0, ""], _new joinString ", "], ALERT_COLOUR] call EFUNC(notify,notify);
    } forEach _keep;
} forEach +GVAR(slots);

// SELF AID: the player's own slot while his setting has it on.
if ("self_aid" in GVAR(profiles)) then {
    private _self = GVAR(slots) getOrDefault ["self_aid", []];
    private _has = (_self findIf {(_x # 0) isEqualTo player}) >= 0;
    if (GVAR(selfAid) && {alive player} && {!_has}) then {GVAR(slots) set ["self_aid", [[player, true, -1, CBA_missionTime]]]};
    if (!GVAR(selfAid) && _has) then {GVAR(slots) set ["self_aid", []]};
};

[] call FUNC(contactMarkers);
[] call FUNC(threatScan);
