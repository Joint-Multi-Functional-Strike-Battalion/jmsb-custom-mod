#include "script_component.hpp"
/*
 * Author: YonV
 * The mix tick (TICK_S): every player's gain and ear re-asked and sent on a
 * change, and whether he is received (FUNC(speaker)) - distance and bearing
 * move every moment, the rest arrives by hook. Speakers gone from the game
 * are forgotten (and no longer received). A join the server has not answered
 * within ROOM_ANSWER_S, or a connect the extension has not finished within
 * ROOM_CONNECT_S, is asked again - the connect said once to the player.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_tick
 *
 * Public: No
 */

if (GVAR(state) isEqualTo ROOM_JOINING && {CBA_missionTime - GVAR(since) > GVAR(waitS)}) exitWith {
    WARNING_1("voice server: no answer in %1 s - asking again",GVAR(waitS));
    if (GVAR(waitS) isEqualTo ROOM_CONNECT_S && !GVAR(toldError)) then {
        GVAR(toldError) = true;
        [VOICE_TITLE, NO_ANSWER_TEXT] call EFUNC(notify,notify);
    };
    GVAR(state) = ROOM_IDLE;
    [] call FUNC(roomJoin);
};
if (GVAR(state) isNotEqualTo ROOM_LIVE || isNull player) exitWith {};

private _seen = [];
{
    if (_x isEqualTo player || !(_x isKindOf "CAManBase")) then {continue};
    _seen pushBack (getPlayerUID _x);
    [_x] call FUNC(speaker);
} forEach allPlayers;
{
    GVAR(sent) deleteAt _x;
} forEach ((keys GVAR(sent)) select {!(_x in _seen)});
{
    if (GVAR(subs) deleteAt _x) then {["subscribe", [_x, false]] call FUNC(ext)};
} forEach ((keys GVAR(subs)) select {!(_x in _seen)});
{
    GVAR(q) deleteAt _x;
} forEach ((keys GVAR(q)) select {!((_x select [0, _x find "|"]) in _seen)});
