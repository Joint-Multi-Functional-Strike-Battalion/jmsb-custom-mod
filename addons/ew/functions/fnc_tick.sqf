#include "script_component.hpp"
/*
 * Author: JMSB
 * THE DF TICK (server, CBA per-frame handler at the DF tick setting):
 *
 *   1. upkeep: drop jammers, decoys and emitters that are gone
 *   2. collect every emitter (RF nodes, own jammers, external, jamming sites)
 *   3. sensors: the emitting RF nodes that can DF (FUNC(sensor))
 *   4. intercept: each emitter radiating this tick - a set carrying traffic
 *      always, an idle one at its EMCON beacon duty, SILENT never - is heard
 *      by up to CUTS_PER_EMITTER sensors of each other side, nearest first;
 *      each one that hears it lays a cut (FUNC(detect), FUNC(cut))
 *   5. tracks: crossed into fixes (FUNC(fix)); a track nobody heard for the
 *      lifetime setting is dropped
 *   6. warnings and slices (FUNC(spotWarn), FUNC(publish))
 *
 * The side of a sensor is the side its node was registered with, so an AI
 * side DFs players exactly as players DF it - when RF counts AI nodes. RF
 * counts none by default, so with the enemy AI EW skill at BASIC or above the
 * enemy side's AI groups are sensors too (FUNC(aiSensors), at most
 * AI_DF_TRIES of them tried per emitter), their GPS kept by the spoof engine
 * (FUNC(spoofTick)), and a fresh fix of theirs is answered (FUNC(aiReact)).
 *
 * A cut is measured from where the sensor stands and plotted from where its
 * GPS says it stands (QGVAR(gps), FUNC(spoof)): a spoofed set's fixes land
 * off target, player's or AI's.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [LINKFUNC(tick), GVAR(dfTick), []] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

if (!isServer) exitWith {};

[] call FUNC(upkeep);
// The jammers first, so what radiates this tick is what they are now:
// AUTO's engage check, then battery and heat.
[] call FUNC(jamAuto);
[] call FUNC(jamPower);

private _emitters = [] call FUNC(collect);
GVAR(lastEmitters) = createHashMap;
{
    GVAR(lastEmitters) set [_x get "id", _x];
} forEach _emitters;

private _sensors = [];
{
    private _s = [_x] call FUNC(sensor);
    if (_s isNotEqualTo []) then {
        _s params ["_err", "_bands", "_sens", "_gain"];
        private _pos = _x get "pos";
        private _obj = _x get "object";
        private _offset = (_obj getVariable [QGVAR(gps), [GPS_GOOD, [0, 0]]]) select 1;
        _sensors pushBack [
            _x get "side", _x get "id", _pos, _err, _bands, _sens, _gain,
            _pos vectorAdd [_offset select 0, _offset select 1, 0], false
        ];
    };
} forEach _emitters;

// THE ENEMY AI'S SENSORS (DESIGN_EW "Both ways"), and the GPS of the AI men
// the spoof engine keeps. The enemy side is worked out from the mission
// (jmfsb_common_fnc_enemySide, D59) and looked at again every
// AI_SET_REFRESH_S - side relations seldom change, and it logs when unsure.
private _aiSide = "";
private _aiMen = [];
if (GVAR(aiSkill) > AI_OFF) then {
    if ((CBA_missionTime - GVAR(aiSideAt)) >= AI_SET_REFRESH_S) then {
        GVAR(aiSide) = str (call EFUNC(common,enemySide));
        GVAR(aiSideAt) = CBA_missionTime;
    };
    _aiSide = GVAR(aiSide);
    ([_aiSide] call FUNC(aiSensors)) params ["_aiSensors", "_men"];
    _sensors append _aiSensors;
    _aiMen = _men;
};
[GVAR(dfTick), _aiMen] call FUNC(spoofTick);
private _sides = [];
{
    _sides pushBackUnique (_x select 0);
} forEach _sensors;

{
    private _e = _x;
    private _from = _e get "pos";
    if ((_e get "source") isEqualTo SRC_RF) then {
        private _emcon = _e get "emcon";
        private _duty = [BEACON_DUTY select (_emcon min EMCON_SILENT), 1] select ((_e get "tx") && _emcon < EMCON_SILENT);
        if (random 1 >= _duty) then {continue};
    };
    {
        private _side = _x;
        if (_side isEqualTo (_e get "side")) then {continue};
        private _cands = _sensors select {(_x select 0) isEqualTo _side && {((_x select 2) distance _from) <= DETECT_MAX_M}};
        // NEAREST FIRST: sorted on [distance, index], then mapped back.
        private _order = [];
        {
            _order pushBack [(_x select 2) distance _from, _forEachIndex];
        } forEach _cands;
        _order sort true;
        _cands = _order apply {_cands select (_x select 1)};
        private _taken = 0;
        private _aiTries = 0;
        {
            if (_taken >= CUTS_PER_EMITTER) exitWith {};
            _x params ["", "_sid", "_spos", "_err", "_bands", "_sens", "_gain", "_gpsPos", "_ai"];
            // An AI sensor holds no RF node, so no key of anybody's; and a
            // big enemy force is tried only so far.
            if (_ai) then {
                if (_aiTries >= AI_DF_TRIES) then {continue};
                _aiTries = _aiTries + 1;
            };
            private _shared = [[], [_e get "id", _sid] call EFUNC(rf,sharedNets)] select ((_e get "source") isEqualTo SRC_RF && !_ai);
            private _det = [_e, _spos, _bands, _sens, _gain, _shared isNotEqualTo []] call FUNC(detect);
            if (_det isEqualTo []) then {continue};
            [_side, _e, _spos, _err, _det, _shared, _gpsPos] call FUNC(cut);
            _taken = _taken + 1;
        } forEach _cands;
    } forEach _sides;
} forEach _emitters;

private _now = CBA_missionTime;
{
    private _side = _x;
    private _tracks = _y;
    private _lost = [];
    {
        private _track = _y;
        if ((_now - (_track get "last")) > GVAR(trackTtl)) then {
            _lost pushBack _x;
            continue;
        };
        if ([_track] call FUNC(fix)) then {
            private _fix = _track get "fix";
            [QGVAR(fix), [_side, _x, _fix, _track get "fixErr", _track get "class"]] call CBA_fnc_localEvent;
            [_side, THREAT_FIX, format ["%1 %2 FIXED AT %3, +-%4 M", _x, _track get "class", mapGridPosition _fix, _track get "fixErr"], "SEND THE FIX OR TASK FIRES"] call FUNC(warnSide);
        };
        // The enemy AI answers every fix it crossed this tick, not only the
        // first (FUNC(aiReact) keeps its own cooldown per track).
        if (_side isEqualTo _aiSide && (_track getOrDefault ["fixAt", -1]) isEqualTo _now) then {
            [_side, _track] call FUNC(aiReact);
        };
    } forEach _tracks;
    {
        private _track = _tracks deleteAt _x;
        GVAR(trackIndex) deleteAt (_side + "|" + (_track get "emitter"));
        [QGVAR(trackLost), [_side, _x]] call CBA_fnc_localEvent;
    } forEach _lost;
} forEach GVAR(tracks);

private _players = allPlayers - entities "HeadlessClient_F";
[_players] call FUNC(spotWarn);
[_players] call FUNC(publish);
