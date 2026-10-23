#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: each player's EW slice - his side's tracks and his own state - sent
 * with publicVariableClient only when it changed (positions on a 10 m grid,
 * dB as integers, so standing still is not a change). Tracks are the
 * SIDE's: what one sensor hears, every man of the side sees. Nothing of the
 * other side's picture is ever sent to him.
 *
 * Slice (jmfsb_ew_slice), an array:
 *   0 side                  STRING
 *   1 tracks                [[id, band, dBm, class, named, fix [x, y] or [],
 *                             fix error m, confidence 0-1, last heard,
 *                             cuts [[[x, y], bearing, error, time], ...],
 *                             fix time, MHz (FUNC(trackMhz))], ...]
 *   2 his nodes             [[id, profile, emcon, exposure m, nets], ...]
 *   3 spectrum where he is  [[band, noise dBm, floor dBm], ...]
 *   4 kit                   [receiver, jammer, vehicle jammer, isr]
 *   5 his jammer            [mode, band, track, net, power index, duty index,
 *                            on, dBm, radius, device id, on the air,
 *                            [operation, engaged, what engaged it],
 *                            [pattern, azimuth], [filter, tuned MHz],
 *                            [battery Wh, battery full Wh, heat %, cutout,
 *                             generator, fuel %, W in, W drawn]] or []
 *   6 GPS                   [state, [dx, dy]] (FUNC(spoof))
 *   7 threats               [[time, kind, detail, what to do], ...]
 *   8 decoys he has out     NUMBER
 *   9 his side's jammers    [[[x, y], mode, on the air, device id], ...]
 *
 * Called with a few players and no prune right after one of them changed
 * something (a jammer setting, a decoy, EMCON), so the screen answers the
 * press now rather than on the next DF tick.
 *
 * Arguments:
 * 0: Players <ARRAY of OBJECTs>
 * 1: Forget clients not in the list (optional, default true) <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [allPlayers] call jmfsb_ew_fnc_publish
 *
 * Public: No
 */

params [["_players", [], [[]]], ["_prune", true, [false]]];

private _fnc_grid = {
    params ["_p"];
    [round ((_p select 0) / SLICE_GRID_M) * SLICE_GRID_M, round ((_p select 1) / SLICE_GRID_M) * SLICE_GRID_M]
};
private _showCuts = GVAR(fixWindow) * 2;
private _now = CBA_missionTime;

// One picture per side, built once and handed to every man of it.
private _bySide = createHashMap;
{
    private _list = [];
    {
        private _t = _y;
        private _fix = _t get "fix";
        private _cuts = ((_t get "cuts") select {(_now - (_x select 3)) <= _showCuts}) apply {
            [[_x select 0] call _fnc_grid, round (_x select 1), round (_x select 2), round (_x select 3)]
        };
        _list pushBack [
            _x, _t get "band", _t get "dbm", _t get "class", _t get "named",
            if (_fix isEqualTo []) then {[]} else {[_fix] call _fnc_grid},
            _t get "fixErr", _t get "conf", round (_t get "last"), _cuts,
            round (_t getOrDefault ["fixAt", 0]), [_t] call FUNC(trackMhz)
        ];
    } forEach _y;
    _list sort true;
    _bySide set [_x, _list];
} forEach GVAR(tracks);

private _jamsBySide = createHashMap;
{
    private _host = _y get "host";
    if (isNull _host) then {continue};
    private _side = _y get "side";
    private _list = _jamsBySide getOrDefault [_side, []];
    _list pushBack [[getPosASL _host] call _fnc_grid, _y get "mode", _y get "tx", _y get "devId"];
    _jamsBySide set [_side, _list];
} forEach GVAR(jammers);

private _clients = [];
{
    private _p = _x;
    private _uid = getPlayerUID _p;
    private _side = str side group _p;
    private _client = owner _p;
    _clients pushBack _client;

    private _nodes = ([_p, []] call EFUNC(rf,nodesFor)) apply {
        _x params ["_id", "", "_profile", "_fill"];
        private _state = ([_id] call EFUNC(rf,nodeInfo)) getOrDefault ["state", createHashMap];
        private _emcon = _state getOrDefault ["emcon", 0];
        [_id, _profile, _emcon, [_profile, _emcon] call FUNC(exposure), _fill apply {_x select 0}]
    };

    private _eye = eyePos _p;
    private _spectrum = BANDS_ALL apply {
        [_x, round ([_eye, _x, "", 0] call EFUNC(rf,noise)), round ((([_x] call EFUNC(rf,bandInfo)) param [2, 0]))]
    };

    private _kit = [_p] call FUNC(kit);
    private _j = GVAR(jammers) getOrDefault ["ew_jam_" + _uid, createHashMap];
    private _jam = if (count _j == 0) then {[]} else {
        private _host = _j get "host";
        (_host getVariable [QGVAR(power), JAM_POWER_FRESH]) params ["_wh", "_heat", "_flat", "_cutout", "_in", "_draw", "_gen"];
        [
            _j get "mode", _j get "band", _j get "track", _j get "net", _j get "power",
            _j get "duty", _j get "on", _j getOrDefault ["dBm", 0], round (_j getOrDefault ["radius", 0]),
            _j get "devId", _j get "tx",
            [_j get "operation", _j get "engaged", _j get "engagedWhy"],
            [_j get "pattern", _j get "azimuth"],
            [_j get "filter", _j get "freq"],
            [round _wh, round GVAR(jamBatteryWh), round _heat, _cutout, _gen, round (fuel _host * PERCENT), round _in, round _draw]
        ]
    };

    private _slice = [
        _side,
        _bySide getOrDefault [_side, []],
        _nodes,
        _spectrum,
        [_kit get "receiver", !isNull (_kit get "host"), _kit get "vehicle", _kit get "isr"],
        _jam,
        [_p, [0, GVAR(dfTick)] select _prune] call FUNC(spoof),
        GVAR(threats) getOrDefault [_uid, []],
        {(_x select 1) isEqualTo _uid} count (values GVAR(decoys)),
        _jamsBySide getOrDefault [_side, []]
    ];

    if ((GVAR(sent) getOrDefault [_client, []]) isEqualTo _slice) then {continue};
    GVAR(sent) set [_client, _slice];
    if (!isMultiplayer || {_client == clientOwner}) then {
        [QGVAR(slice), _slice] call FUNC(receiveSlice);
    } else {
        GVAR(slice) = _slice;
        _client publicVariableClient QGVAR(slice);
    };
} forEach _players;

if (!_prune) exitWith {};
{
    GVAR(sent) deleteAt _x;
} forEach ((keys GVAR(sent)) - _clients);
