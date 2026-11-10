#include "script_component.hpp"
/*
 * Author: YonV
 * The asymmetric commander's installations - the physical network the intel
 * economy points at (new.md section 5).
 *
 * ALiVE does NOT record an installation as an objective of its own. It hangs
 * it off the objective it was built in, as one key per kind on that
 * objective's hash - "HQ", "factory", "depot", "roadblocks" - whose value is
 * the building serialised by OPCOM's convertObject: [[x, y], className], or
 * [] once it is gone. objectiveType never carries these names (it is the
 * placement label, MIL/CIV/CUS/CCU), so a filter on it answers empty forever.
 * Verified against mil_opcom fnc_OPCOM.sqf (createAsymmetricInstallation,
 * convertObject) and fnc_INS_helpers.sqf (the four HashSet sites).
 *
 * A conventional commander has none of these, so a map with no asymmetric
 * commander returns empty and every consumer stays quiet rather than
 * inventing targets.
 *
 * Arguments:
 * 0: Kinds wanted <ARRAY of STRING> (optional, default the design's four;
 *    "hq"/"factory"/"depot"/"roadblocks", any case)
 *
 * Return Value:
 * [[id <STRING>, pos <ARRAY>, size <NUMBER>, type <STRING>], ...] <ARRAY>
 * id is unique per installation (objectiveID_kind), pos is the building's
 * own position, size is the parent objective's, type is the lower-case kind.
 *
 * Example:
 * [] call jmfsb_adapter_alive_fnc_installations
 */

// A bare `call` hands over the caller's own _this (a hashmap, in the hacking
// menus - rpt 2026-10-08); anything that is not a list means "the default".
private _args = if (_this isEqualType []) then {_this} else {[]};
_args params [["_want", ["factory", "hq", "depot", "roadblocks"], [[]]]];

if (!GVAR(ready)) exitWith {[]};

_want = _want apply { toLower _x };

// ALiVE's key for the recruitment HQ is upper-case; the rest are lower.
private _kinds = [["HQ", "hq"], ["factory", "factory"], ["depot", "depot"], ["roadblocks", "roadblocks"]] select {
    (_x # 1) in _want
};

private _out = [];
{
    _x params ["", "_ctype", "", "", "_inst"];
    if (_ctype isNotEqualTo "asymmetric") then {continue};

    {
        private _obj = _x;
        if ([_obj, "deleted", false] call ALiVE_fnc_hashGet) then {continue};

        private _id = [_obj, "objectiveID", ""] call ALiVE_fnc_hashGet;
        if (_id isEqualTo "") then {continue};
        private _size = [_obj, "size", 150] call ALiVE_fnc_hashGet;

        {
            _x params ["_key", "_low"];
            // [[x, y], className] while the building stands, [] after
            private _ref = [_obj, _key, []] call ALiVE_fnc_hashGet;
            if (!(_ref isEqualType []) || {count _ref < 2} || {!((_ref # 0) isEqualType [])} || {count (_ref # 0) < 2}) then {continue};
            _out pushBack [format ["%1_%2", _id, _low], [_ref # 0 # 0, _ref # 0 # 1, 0], _size, _low];
        } forEach _kinds;
    } forEach ([_inst, "objectives", []] call ALiVE_fnc_hashGet);
} forEach (call FUNC(commanders));

_out
