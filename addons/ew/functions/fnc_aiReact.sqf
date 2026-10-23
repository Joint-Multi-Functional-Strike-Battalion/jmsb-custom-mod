#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the enemy AI answers a fix its side's ES made (DESIGN_EW "Both
 * ways: AI EW", "On a fix"), by the enemy AI EW skill setting:
 *
 *   1 BASIC   the side's AI groups within the reaction range of the fix that
 *             the report reaches (FUNC(aiLink), the comms gate: voice inside
 *             50 m, otherwise one radio hop of 2 s that gets through with the
 *             link's quality) go AWARE and watch the fix (FUNC(aiAlert)); and
 *             the transmitting player goes through the one consequence path,
 *             jmfsb_reaction's ladder (source "df": a silent flag, MAJOR on a
 *             flagged man - shells, a drone, the neighbourhood told)
 *   2 ACTIVE  also sends a drone to look (jmfsb_uas_fnc_respondTo)
 *   3 SMART   also sends a QRF to the fix (jmfsb_qrf_fnc_onCaptured, which
 *             asks the hostile commander through the adapter)
 *
 * Nobody in range, or nobody the report reaches: nothing - a side without a
 * link to the fix does not know it exists. One reaction per track per
 * AI_REACT_COOLDOWN_S; drones and QRFs once per side per
 * AI_DISPATCH_COOLDOWN_S. A fix on a friend of the side is ignored. A decoy
 * is answered like the set it copies - that is what it is for.
 *
 * Arguments:
 * 0: The side that made the fix, as RF writes it <STRING>
 * 1: Track <HASHMAP>
 *
 * Return Value:
 * Whether anyone was told <BOOL>
 *
 * Example:
 * ["EAST", _track] call jmfsb_ew_fnc_aiReact
 *
 * Public: No
 */

params [["_side", "", [""]], ["_track", createHashMap, [createHashMap]]];

private _now = CBA_missionTime;
if ((_now - (_track getOrDefault ["aiReactAt", -1e9])) < AI_REACT_COOLDOWN_S) exitWith {false};
private _fix = _track getOrDefault ["fix", []];
if (_fix isEqualTo []) exitWith {false};
private _e = GVAR(lastEmitters) getOrDefault [_track get "emitter", createHashMap];
if (count _e == 0) exitWith {false};

private _sideObj = [_side] call EFUNC(common,sideFromText);
private _theirs = [_e get "side"] call EFUNC(common,sideFromText);
if (_sideObj isEqualTo sideUnknown || (_sideObj getFriend _theirs) >= HOSTILE_BELOW) exitWith {false};

private _at = [_fix select 0, _fix select 1, 0];
private _groups = allGroups select {
    (side _x) isEqualTo _sideObj && alive leader _x && !isPlayer leader _x
    && ((leader _x) distance2D _at) <= GVAR(aiReactRange)
};
if (_groups isEqualTo []) exitWith {false};
_track set ["aiReactAt", _now];

// THE REPORT comes from the sensors that cut it: each group hears whichever
// of them it has the best link to.
private _origins = ((_track get "cuts") select {(_now - (_x select 3)) <= GVAR(fixWindow)}) apply {
    [(_x select 0) select 0, (_x select 0) select 1, 0]
};
private _delays = [];
{
    private _group = _x;
    private _best = [0, 0];
    {
        private _link = [_x, _group] call FUNC(aiLink);
        if ((_link select 0) > (_best select 0)) then {_best = _link};
    } forEach _origins;
    _best params ["_chance", "_delay"];
    if (random 1 >= _chance) then {continue};
    _delays pushBack _delay;
    [{
        [QGVAR(aiAlert), _this, leader (_this select 0)] call CBA_fnc_targetEvent;
    }, [_group, _at], _delay] call CBA_fnc_waitAndExecute;
} forEach _groups;
if (_delays isEqualTo []) exitWith {
    TRACE_2("AI fix not reported - comms gate",_side,_track get "id");
    false
};
private _first = selectMin _delays;

// THE ONE CONSEQUENCE PATH, for the man on the set.
private _obj = _e get "object";
private _players = (if (_obj isKindOf "CAManBase") then {[_obj]} else {crew _obj}) select {isPlayer _x};
if (_players isNotEqualTo []) then {
    [{
        [QEGVAR(reaction,event), _this] call CBA_fnc_serverEvent;
    }, [_players select 0, AI_REACT_SOURCE], _first] call CBA_fnc_waitAndExecute;
};

// ACTIVE and SMART send something to the fix.
if (GVAR(aiSkill) >= AI_ACTIVE && (_now - (GVAR(aiDispatchAt) getOrDefault [_side, -1e9])) >= AI_DISPATCH_COOLDOWN_S) then {
    GVAR(aiDispatchAt) set [_side, _now];
    [{
        params ["_sideObj", "_theirs", "_at"];
        if (!isNil QEFUNC(uas,respondTo)) then {[_sideObj, _at] call EFUNC(uas,respondTo)};
        if (GVAR(aiSkill) >= AI_SMART && !isNil QEFUNC(qrf,onCaptured)) then {
            [AI_QRF_TAG, _theirs, _at, AI_QRF_RADIUS] call EFUNC(qrf,onCaptured);
        };
    }, [_sideObj, _theirs, _at], _first] call CBA_fnc_waitAndExecute;
};

private _skill = AI_SKILL_NAMES select GVAR(aiSkill);
INFO_4("AI %1 (%2) answers fix %3 at %4",_side,_skill,_track get "id",mapGridPosition _at);
[QGVAR(aiReact), [_side, _track get "id", _at, count _delays]] call CBA_fnc_localEvent;
true
