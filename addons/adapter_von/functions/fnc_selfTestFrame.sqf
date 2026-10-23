#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every frame for TEST_WINDOW_S after fnc_selfTest: times T3 (own PTT
 * press, any PTT input, to own getPlayerChannel change; remote changes and
 * pushed key events counted), watches T2
 * (who talked on Group while Group voice was off) and T4 (when C2
 * membership changed as seen here, by radioChannelInfo). At the end Group
 * voice is put back and the results go to the RPT.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], _handle] call jmfsb_adapter_von_fnc_selfTestFrame
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

private _test = GVAR(test);
private _now = diag_tickTime;
private _t = _now - (_test get "start");

// T3: own PTT -> own channel
private _ptt = ([false] call FUNC(ptt)) select 0;
if (_ptt && (_test get "pttAt") < 0) then {
    _test set ["pttAt", _now];
    _test set ["pttFrame", diag_frameNo];
};
if (!_ptt) then {_test set ["pttAt", -1]};
private _own = getPlayerChannel player;
if (_own isNotEqualTo (_test get "ownCh")) then {
    if (_own > CH_NONE && (_test get "pttAt") >= 0) then {
        (_test get "latency") pushBack [round ((_now - (_test get "pttAt")) * MS_PER_S), diag_frameNo - (_test get "pttFrame"), _own];
    };
    _test set ["ownCh", _own];
};

// T3 remote changes, T2 Group talkers
{
    if (_x isEqualTo player || !(_x isKindOf "CAManBase")) then {continue};
    private _ch = getPlayerChannel _x;
    private _key = "ch" + getPlayerUID _x;
    if (_ch isNotEqualTo (_test getOrDefault [_key, CH_NONE])) then {
        _test set [_key, _ch];
        _test set ["remote", (_test get "remote") + 1];
        if (_ch isEqualTo CH_GROUP) then {(_test get "heardGroup") pushBackUnique name _x};
    };
} forEach allPlayers;

// T4: C2 membership as this client sees it
private _c2 = _test get "c2";
if (_c2 > CUSTOM_NONE) then {
    private _in = player in ((radioChannelInfo _c2) param [3, []]);
    private _log = _test get "member";
    if (_log isEqualTo [] || {((_log select -1) select 1) isNotEqualTo _in}) then {
        _log pushBack [round (_t * MS_PER_S), _in];
    };
};

if (_t < TEST_WINDOW_S) exitWith {};

[_handle] call CBA_fnc_removePerFrameHandler;
(_test get "group") params ["_chat", "_voice"];
CH_GROUP enableChannel [_chat, _voice];
INFO_1("VON T2 enableChannel: Group voice restored. Group talkers seen while it was off: %1 (did you hear them?)",_test get "heardGroup");
INFO_1("VON T3 getPlayerChannel: own [ms, frames, channel] per press: %1",_test get "latency");
INFO_1("VON T3 getPlayerChannel: remote channel changes seen: %1 (0 with others talking = it does not report remote players; the pushed key events cover them)",_test get "remote");
INFO_1("VON T3 pushed key events received (key-down and key-up): %1",_test get "keyed");
INFO_1("VON T4 custom channel: membership seen here [ms since start, member]: %1",_test get "member");
GVAR(test) = createHashMap;
