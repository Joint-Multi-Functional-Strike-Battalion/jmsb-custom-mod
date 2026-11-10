#include "script_component.hpp"
/*
 * Author: YonV
 * Every camp ALiVE's military placement stood up, as a hunt pool.
 *
 * ALiVE has no camp registry. A random camp is a composition dropped on a
 * strategic cluster, and the only record it leaves is three keys written back
 * onto that cluster's hash at placement (mil_placement fnc_MP.sqf:1330-1332):
 * "campSafePos" (where it stands), "campEnvelope" (its footprint) and
 * "campSeats".
 *
 * NOT THE GLOBAL TABLE. The module COPIES its clusters before it works on
 * them (fnc_MP.sqf:788, ALIVE_fnc_copyClusters) and stores the copies on its
 * own logic as "objectives" and "objectivesLand" (fnc_MP.sqf:804, 844 -
 * OOsimpleOperation is a setVariable); the camp loop later writes onto those
 * same copies. ALIVE_clustersMil never learns of a camp. So this reads every
 * placement module's stored clusters, both lists (they share elements),
 * once per clusterID.
 *
 * WHOSE CAMP IS DERIVED, NOT STORED. The cluster does not know who garrisons
 * it, and a camp changes hands when the war moves. The side is whoever holds
 * the ground now: the majority side of the entity profiles within
 * CAMP_SIDE_RADIUS. An empty camp answers sideUnknown - a consumer that hunts
 * hostile camps must drop those, a tent with nobody in it is not a target.
 *
 * Arguments: None
 *
 * Return Value:
 * [[id <STRING>, pos <ARRAY>, size <NUMBER>, side <SIDE>], ...] <ARRAY>
 * id is "camp_" + clusterID, stable for the life of the mission.
 *
 * Example:
 * call jmfsb_adapter_alive_fnc_camps
 *
 * Public: Yes
 */

if (!GVAR(ready)) exitWith {[]};

private _out = [];
private _done = createHashMap;
{
    private _logic = _x;
    private _clusters = (_logic getVariable ["objectives", []]) + (_logic getVariable ["objectivesLand", []]);

    {
        private _cluster = _x;
        if !(_cluster isEqualType [] && {count _cluster > HASH_VALUES}) then {continue};
        private _at = [_cluster, "campSafePos", []] call ALiVE_fnc_hashGet;
        if (_at isEqualTo []) then {continue};

        private _id = [_cluster, "clusterID", ""] call ALiVE_fnc_hashGet;
        if (_id in _done) then {continue};
        _done set [_id, true];
        private _size = [_cluster, "campEnvelope", 0] call ALiVE_fnc_hashGet;
        if (_size <= 0) then { _size = [_cluster, "size", 150] call ALiVE_fnc_hashGet };

        // Majority side of what stands there. Text sides from the profiles,
        // one side object out - the same translation every other read does.
        private _tally = createHashMap;
        {
            private _t = toUpper ([_x, "side", ""] call ALiVE_fnc_hashGet);
            if (_t isNotEqualTo "") then { _tally set [_t, (_tally getOrDefault [_t, 0]) + 1] };
        } forEach ([_at, CAMP_SIDE_RADIUS, ["all", "entity"]] call ALIVE_fnc_getNearProfiles);
        private _best = ""; private _n = 0;
        {
            if (_y > _n) then { _best = _x; _n = _y };
        } forEach _tally;
        private _side = [_best, sideUnknown] call EFUNC(common,sideFromText);

        _out pushBack [format ["camp_%1", _id], _at, _size, _side];
    } forEach _clusters;
} forEach (allMissionObjects PLACEMENT_CLASS);

_out
