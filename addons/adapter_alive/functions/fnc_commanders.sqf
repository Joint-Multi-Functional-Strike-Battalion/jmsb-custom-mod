#include "script_component.hpp"
/*
 * Author: YonV
 * Every ALiVE AI commander: who it is, what kind of war it runs, what it
 * fights with, and its module logic.
 *
 * THE LOGIC IS RESOLVED BY POSITION, not read from the instance. Verified in
 * source: the OPCOM handler hash (fnc_OPCOM.sqf:288-300) carries side,
 * factions, controltype and position - but NOT the module object. The TAOR
 * read needs the module, because placements are synchronised to it, so the
 * nearest OPCOM module logic to the instance's own position is matched here,
 * once, in the one place that knows about it.
 *
 * A commander whose logic does not resolve still comes back - with objNull -
 * so probe 1 shows the failure instead of silently reporting no TAORs.
 *
 * Arguments: None
 *
 * Return Value:
 * [[side <SIDE>, controltype <STRING>, faction <STRING>, logic <OBJECT>,
 * instance <ARRAY>], ...] - controltype is "invasion", "occupation" or
 * "asymmetric" <ARRAY>
 *
 * Example:
 * call jmfsb_adapter_alive_fnc_commanders
 */

// A machine that cannot ask ALiVE - every client, and the server before
// ready - answers from the published summary instead of going silent: the
// hacking console runs its whole product menu off this on clients. Logic
// and instance slots carry safe empties; the consumers that need those
// (the probes) are server-side and never take this branch.
if (!GVAR(ready)) exitWith {
    (missionNamespace getVariable [QGVAR(commandersPub), []]) apply {
        _x params ["_s", "_t", "_f"];
        [_s, _t, _f, objNull, []]
    }
};

private _logics = allMissionObjects OPCOM_CLASS;

private _out = [];
{
    private _inst = _x;

    private _sideText = toUpper ([_inst, "side", ""] call ALiVE_fnc_hashGet);
    private _side = [_sideText, sideUnknown] call EFUNC(common,sideFromText);
    if (_side isEqualTo sideUnknown) then {continue};

    private _type = toLower ([_inst, "controltype", "invasion"] call ALiVE_fnc_hashGet);

    // "factions" is an ARRAY (fnc_OPCOM.sqf:291); the first is the primary.
    private _faction = ([_inst, "factions", []] call ALiVE_fnc_hashGet) param [0, ""];

    private _pos = [_inst, "position", []] call ALiVE_fnc_hashGet;
    private _logic = objNull;
    if (_pos isNotEqualTo []) then {
        private _best = 1e9;
        {
            private _d = (getPosATL _x) distance2D _pos;
            if (_d < _best) then { _best = _d; _logic = _x };
        } forEach _logics;
    };

    _out pushBack [_side, _type, _faction, _logic, _inst];
} forEach OPCOM_instances;

_out
