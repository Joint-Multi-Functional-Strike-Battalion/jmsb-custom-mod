#include "script_component.hpp"
/*
 * Author: YonV
 * Every AA piece ALiVE is running, as a hunt pool (new.md section 1.1 -
 * jmfsb spawns none of this).
 *
 * TWO READS, ONE POOL. ALIVE_aaProfileBehaviour is what mil_placement
 * registered and how it told each piece to behave; it knows nothing about
 * the SAM site a custom placement or an ORBAT dropped, the Tigris in an
 * armoured column, or anything the commander bought through LOGCOM. Those
 * are found the way ALiVE's own SEAD task finds them (mil_c2istar
 * fnc_taskSEAD.sqf:78-104): every vehicle profile whose class
 * ALiVE_fnc_isAntiAirCapable says can lock the sky. The behaviour string is
 * "" for those - nobody told them anything.
 *
 * ALIVE_aaProfileBehaviour is an ALiVE hash keyed by profileID, written at
 * placement (mil_placement fnc_MP.sqf:1858, custom fnc_CMP.sqf:2164). Each
 * key is joined against the live profile system and PRUNED when the profile
 * is gone - a pool that remembers dead radars lies to the hunt.
 *
 * An ALiVE hash is a CBA hash: keys at index 1, values at index 2 - CBA's own
 * HASH_KEYS/HASH_VALUES macros (x/cba/addons/hashes/script_hashes.hpp:2-3),
 * as ALiVE reads them itself in x_lib fnc_hashRem.sqf:46. Read in exactly one
 * place - here - so the layout has one consumer if it ever changes.
 *
 * Arguments: None
 *
 * Return Value:
 * [[profileID <STRING>, pos <ARRAY>, side <SIDE>, behaviour <STRING>], ...]
 * behaviour is "static" / "roaming" from placement, "" for the rest.
 * behaviour is "static" / "roaming" from placement, "" for the rest.
 *
 * Example:
 * call jmfsb_adapter_alive_fnc_aaTargets
 */

if (!GVAR(ready)) exitWith {[]};

private _out = [];
private _seen = createHashMap;
if (!isNil "ALIVE_aaProfileBehaviour") then {
{
    private _id = _x;
    private _behaviour = [ALIVE_aaProfileBehaviour, _id, ""] call ALiVE_fnc_hashGet;

    private _profile = [ALIVE_profileHandler, "getProfile", _id] call ALIVE_fnc_profileHandler;
    if (isNil "_profile") then {continue};
    if !(_profile isEqualType []) then {continue};
    if (_profile isEqualTo []) then {continue};

    private _pos = [_profile, "position", []] call ALiVE_fnc_hashGet;
    private _sideText = toUpper ([_profile, "side", ""] call ALiVE_fnc_hashGet);
    private _side = [_sideText, sideUnknown] call EFUNC(common,sideFromText);

    if (_pos isNotEqualTo [] && {_side isNotEqualTo sideUnknown}) then {
        _out pushBack [_id, _pos, _side, _behaviour];
        _seen set [_id, true];
    };
} forEach (ALIVE_aaProfileBehaviour select HASH_KEYS);
};

// The rest of the sky's defence: what the profile system holds that can lock
// an aircraft, wherever it came from. ALiVE caches the class test itself.
private _handler = [ALIVE_profileHandler, "profiles"] call ALiVE_fnc_hashGet;
if (!isNil "_handler" && {_handler isEqualType []}) then {
    {
        private _p = _x;
        if !(_p isEqualType []) then {continue};
        if (([_p, "type", ""] call ALiVE_fnc_hashGet) isNotEqualTo "vehicle") then {continue};
        private _id = [_p, "profileID", ""] call ALiVE_fnc_hashGet;
        if (_id isEqualTo "" || {_id in _seen}) then {continue};
        private _cls = [_p, "vehicleClass", ""] call ALiVE_fnc_hashGet;
        if (_cls isEqualTo "" || {!([_cls] call ALiVE_fnc_isAntiAirCapable)}) then {continue};
        private _sideText = toUpper ([_p, "side", ""] call ALiVE_fnc_hashGet);
        private _side = [_sideText, sideUnknown] call EFUNC(common,sideFromText);
        private _pos = [_p, "position", []] call ALiVE_fnc_hashGet;
        if (_pos isNotEqualTo [] && {_side isNotEqualTo sideUnknown}) then {
            _out pushBack [_id, _pos, _side, ""];
            _seen set [_id, true];
        };
    } forEach (_handler select HASH_VALUES);
};

_out
