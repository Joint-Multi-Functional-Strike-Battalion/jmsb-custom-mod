#include "script_component.hpp"
/*
 * Author: JMSB
 * SLICE ZERO (docs/new.md section 9). Four probes, each dumping evidence to
 * the RPT and to the caller's chat. Rule 6: nothing else in the restart
 * merges until all four have passed in a live mission.
 *
 * Every probe prints what it READ as well as what it did, so an assumption
 * about ALiVE's internal shapes is falsified here, in one run, instead of
 * silently producing an empty system three phases later.
 *
 * Arguments:
 * 0: Which probe <STRING>
 * 1: The caller <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_which", "", [""]], ["_caller", objNull, [objNull]]];

if (!isServer) exitWith {};

// ADMINS ONLY, by the server's records (review S7). The probes spawn a squad,
// call a fire mission and hold an objective; they came on a CBA event any
// client could raise, from a chat command anyone could type. A host and a
// single player pass as the server. The caller is the sender, never a unit
// the request names.
if !([] call EFUNC(common,senderIsAdmin)) exitWith {
    WARNING_2("probe '%1': refused - machine %2 is not an admin",_which,remoteExecutedOwner);
};
if (isRemoteExecuted) then {
    _caller = ([] call EFUNC(common,sender)) select 1;
};

private _say = {
    diag_log text format ["[jmfsb adapter PROBE] %1", _this];
    [format ["PROBE: %1", _this]] remoteExec ["systemChat", 0];
};

// The perf probe runs WHETHER OR NOT ALiVE is up. It is the one probe that
// answers a question about the machine rather than about ALiVE, and a frame
// rate you cannot read until the adapter reports in is no use at exactly the
// moment you want it - a mission that is crawling before ALiVE finishes
// initialising is a mission you need numbers from.
if (toLower _which isNotEqualTo "perf" && {!GVAR(ready)}) exitWith {
    "adapter NOT READY - ALiVE is still initialising, or is not loaded. Nothing to probe yet." call _say;
};

switch (toLower _which) do {

    // --- 1: the reads --------------------------------------------------
    case "alive.reads": {
        private _cmds = call FUNC(commanders);
        format ["1/4 OPCOM n=%1", count _cmds] call _say;

        {
            _x params ["_side", "_type", "_faction", "_logic"];
            format ["    %1 / %2 / faction=%3 / logic=%4",
                _side, _type, _faction,
                ["NOT RESOLVED - taor read will be empty", "resolved"] select (!isNull _logic)] call _say;

            ([_side] call FUNC(taorFor)) params ["_taor", "_black"];
            format ["    taor=%1 blacklist=%2",
                ["(none - whole map)", str _taor] select (_taor isNotEqualTo []),
                ["(none)", str _black] select (_black isNotEqualTo [])] call _say;
        } forEach _cmds;

        private _aa = call FUNC(aaTargets);
        format ["    AA pool n=%1 first=%2", count _aa, _aa param [0, "(empty)"]] call _say;
        if (_aa isEqualTo [] && {!isNil "ALIVE_aaProfileBehaviour"}) then {
            format ["    NOTE: aaProfileBehaviour has %1 raw key(s) but none resolved to a live profile",
                count (ALIVE_aaProfileBehaviour select 1)] call _say;
        };
    };

    // --- 2: spawn -> profile -> move -----------------------------------
    case "alive.squad": {
        if (isNull _caller) exitWith {"2/4 needs a caller position" call _say};

        private _cmds = call FUNC(commanders);
        if (_cmds isEqualTo []) exitWith {"2/4 no commanders to borrow a side from" call _say};

        // borrow the first commander's side and faction - WHO always comes
        // from ALiVE, even in a probe (rule 2)
        (_cmds select 0) params ["_side", "", "_faction"];
        private _kinds = [];
        {
            if (getNumber (_x >> "scope") == 2
                && {getText (_x >> "faction") == _faction}
                && {configName _x isKindOf "CAManBase"}) then {
                _kinds pushBack (configName _x);
            };
        } forEach ("true" configClasses (configFile >> "CfgVehicles"));
        if (_kinds isEqualTo []) exitWith {
            format ["2/4 faction '%1' yields no infantry - cannot spawn honestly", _faction] call _say;
        };

        private _at = (getPosATL _caller) getPos [3000, random 360];
        private _grp = createGroup [_side, true];
        for "_i" from 1 to 4 do {
            _grp createUnit [selectRandom _kinds, _at, [], 20, "NONE"];
        };

        private _profile = [_grp] call FUNC(profileGroup);
        if (_profile isEqualTo []) exitWith {
            "2/4 FAILED - createProfilesFromUnitsRuntime returned no profile" call _say;
        };

        private _pid = [_profile] call FUNC(profileIdOf);
        private _ok = [_profile, getPosATL _caller, 100] call FUNC(profileWaypoint);
        format ["2/4 %1 spawned at %2, profiled '%3', waypoint sent=%4 - the live units are gone by design; watch the PROFILE walk to you and materialise",
            _faction, mapGridPosition _at, _pid, _ok] call _say;
    };

    // --- 3: one fire request -------------------------------------------
    case "alive.fire": {
        if (isNull _caller) exitWith {"3/4 needs a caller position" call _say};

        private _cmds = call FUNC(commanders);
        private _side = sideUnknown;
        {
            _x params ["_cside"];
            if (_cside getFriend (side group _caller) < 0.6) exitWith { _side = _cside };
        } forEach _cmds;
        if (_side isEqualTo sideUnknown) exitWith {
            "3/4 no commander hostile to you - nobody to ask for fire" call _say;
        };

        private _tgt = (getPosATL _caller) getPos [400, random 360];
        private _ok = [_side, _tgt, 1] call FUNC(requestFire);
        format ["3/4 ARTY_REQUEST to %1 at grid %2 placed=%3 - shells are mil_artillery's call (needs its module and an in-range battery with ammo)",
            _side, mapGridPosition _tgt, _ok] call _say;
    };

    // --- 4: capture detection ------------------------------------------
    // Presence plus no hostiles, held - the carry-over condition, on a test
    // objective at the caller. Proves the EVENT path; the real watcher comes
    // with the QRF phase.
    case "alive.capture": {
        if (isNull _caller) exitWith {"4/4 needs a caller position" call _say};

        private _pos = getPosATL _caller;
        format ["4/4 test objective armed at %1 - hold it (%2 m, %3 s, no hostiles inside)",
            mapGridPosition _pos, PROBE_RADIUS, PROBE_HOLD] call _say;

        [{
            params ["_args", "_handle"];
            _args params ["_pos", "_streak"];

            private _inside = allPlayers select {
                alive _x && {(getPosATL _x) distance2D _pos <= PROBE_RADIUS}
            };
            if (_inside isEqualTo []) exitWith { _args set [1, -1] };

            private _side = side group (_inside select 0);
            private _hostile = allUnits findIf {
                alive _x
                && {!isPlayer _x}
                && {(side group _x) getFriend _side < 0.6}
                && {(getPosATL _x) distance2D _pos <= PROBE_RADIUS}
            };
            if (_hostile > -1) exitWith { _args set [1, -1] };

            if (_streak < 0) exitWith { _args set [1, CBA_missionTime] };
            if ((CBA_missionTime - _streak) < PROBE_HOLD) exitWith {};

            [_handle] call CBA_fnc_removePerFrameHandler;

            ["jmfsb_objective_captured",
                ["PROBE", _side, +_pos, PROBE_RADIUS]] call CBA_fnc_globalEvent;

            diag_log text format
                ["[jmfsb adapter PROBE] 4/4 jmfsb_objective_captured raised: '%1' by %2 at %3",
                    "PROBE", _side, mapGridPosition _pos];
            ["PROBE: 4/4 capture detected - jmfsb_objective_captured raised"]
                remoteExec ["systemChat", 0];
        }, 2, [_pos, -1]] call CBA_fnc_addPerFrameHandler;
    };

    // --- 5: whose profile is breaking ALiVE's combat simulator ----------
    // NOT part of slice zero. ALiVE's fnc_profileSimulator throws at its own
    // lines 877 and 896 every few seconds, both times because a vehicle
    // profile's "damage" list holds an entry whose second slot is an array
    // where a number belongs. The errors name ALiVE's file, not the vehicle,
    // so they repeat forever without ever saying what is wrong.
    //
    // Read-only, and deliberately so: the damage list is ALiVE's to write and
    // jmfsb never touches it. This says WHICH class is malformed so it can be
    // kept out of a mission or reported upstream.
    case "alive.damage": {
        if (isNil "ALIVE_profileHandler") exitWith {
            "5 profile handler is not up" call _say;
        };

        private _all = [ALIVE_profileHandler, "getProfiles"] call ALIVE_fnc_profileHandler;
        if (!(_all isEqualType []) || {count _all < 3}) exitWith {
            "5 profile registry is not the shape this reads - ALiVE changed it" call _say;
        };

        private _bad = createHashMap;
        private _seen = 0;

        {
            private _p = _x;
            if (!(_p isEqualType []) || {count _p < 3}) then {continue};

            private _dmg = [_p, "damage", []] call ALIVE_fnc_hashGet;
            if (!(_dmg isEqualType [])) then {continue};

            _seen = _seen + 1;

            // every entry must be [hitpoint name, damage number]
            private _wrong = _dmg select {
                !(_x isEqualType []) || {count _x < 2} || {!((_x select 1) isEqualType 0)}
            };
            if (_wrong isEqualTo []) then {continue};

            private _cls = [_p, "vehicleClass", "(unknown)"] call ALIVE_fnc_hashGet;
            private _row = _bad getOrDefault [_cls, [0, ""]];
            _bad set [_cls, [(_row select 0) + 1, str (_wrong select 0)]];
        } forEach (_all select 2);

        format ["5 checked %1 vehicle profile(s), %2 class(es) malformed", _seen, count _bad] call _say;

        if (count _bad == 0) exitWith {
            "    all damage lists are [name, number] - the simulator errors are not coming from a bad profile here" call _say;
        };

        {
            _y params ["_n", "_sample"];
            format ["    %1 - %2 profile(s), first bad entry %3", _x, _n, _sample] call _say;
        } forEach _bad;
    };

    // --- 6: where the frames are going ----------------------------------
    // NOT slice zero. "The lag" has cost several test runs and every diagnosis
    // so far has been read backwards out of an RPT after the fact. This is the
    // cheap forward measurement: server frame rate, what the engine is carrying
    // and what jmfsb put there, in one line, on demand.
    case "perf": {
        private _prof = -1;
        if (!isNil "ALIVE_profileHandler") then {
            private _all = [ALIVE_profileHandler, "getProfiles"] call ALIVE_fnc_profileHandler;
            if (_all isEqualType [] && {count _all > 2}) then {
                _prof = count (_all select 2);
            };
        };

        format ["6 SERVER fps %1 | units %2 | vehicles %3 | groups %4 | ALiVE profiles %5",
            round diag_fps, count allUnits, count vehicles, count allGroups, _prof] call _say;

        // JMSB's own footprint, counted from each system's registry rather
        // than by sweeping the map - a system that placed nothing says 0 here
        // and is ruled out in one line.
        private _jam = count (missionNamespace getVariable [QEGVAR(jamming,jammers), []]);
        private _watch = count (missionNamespace getVariable [QEGVAR(qrf,watches), []]);

        private _uas = 0;
        if (!isNil QEGVAR(uas,patrols)) then {
            { _uas = _uas + count _y } forEach EGVAR(uas,patrols);
        };

        format ["    jmfsb: jam zones %1 | qrf watches %2 | uas patrols %3",
            _jam, _watch, _uas] call _say;
    };

    default {
        format ["unknown probe '%1' - alive.reads | alive.squad | alive.fire | alive.capture | alive.damage | perf", _which] call _say;
    };
};
