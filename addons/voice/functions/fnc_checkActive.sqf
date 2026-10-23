#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: keeps the active net one of the local player's nets. When it is
 * gone (a call ended, he left a vehicle or his group) it goes back to the
 * net that was active before the call, else his TEAM net, else his first
 * net. HE STARTS ON HIS TEAM NET (user, 2026-10-21: "default to squad
 * comms"): with no active net yet - a fresh start or a respawn - the game's
 * own current channel is not adopted, so the last channel he used is not
 * where he lands. When the game's own channel keys moved him onto another of his nets,
 * that net becomes the active one (not while a cut-off or radio silence
 * holds, when the game may have moved him off a disabled channel). A live
 * call is made active as soon as the voice channel takes it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_checkActive
 *
 * Public: No
 */

private _ids = GVAR(myNets) apply {_x select 0};
if (_ids isEqualTo []) exitWith {};

// a net waiting to become active (a call that went live before the voice
// channel let him on it): tried every tick until it takes or is gone
private _want = GVAR(wantActive);
if (_want isNotEqualTo "") then {
    if (!(_want in _ids) || {[_want] call FUNC(setActive)}) then {GVAR(wantActive) = ""};
};

// ON THE SQUAD NET AS SOON AS THERE IS ONE (user, 2026-10-22: "players need
// to default to channel 1 automatically on role select"). Right after a role
// pick or a respawn the roster has not reached him yet, so his nets are VEH
// and DIRECT only; the fallback below made DIRECT the active net and it stuck
// there, because an active net that is still listed is never looked at again.
// FUNC(toTeam) asks for TEAM for TEAM_WAIT_S; the first tick that lists a TEAM
// net puts him on it.
if (CBA_missionTime < GVAR(wantTeamUntil)) then {
    private _team = _ids findIf {([_x] call FUNC(netKind)) isEqualTo KIND_TEAM};
    if (_team >= 0 && {[_ids select _team] call FUNC(setActive)}) then {GVAR(wantTeamUntil) = 0};
};

private _current = [] call HOOK("current");
if (GVAR(activeNetId) isNotEqualTo "" && GVAR(level) isEqualTo BLOCK_NONE && _current in _ids && _current isNotEqualTo GVAR(activeNetId)) exitWith {
    GVAR(activeNetId) = _current;
    ["netSwitch", _current] call FUNC(playCue);
    [QGVAR(netsChanged), []] call CBA_fnc_localEvent;
};

if (GVAR(activeNetId) in _ids) exitWith {};

private _back = GVAR(beforeCall);
GVAR(beforeCall) = "";
if !(_back in _ids) then {
    private _team = _ids findIf {([_x] call FUNC(netKind)) isEqualTo KIND_TEAM};
    _back = _ids select (_team max 0);
};
GVAR(activeNetId) = "";
[_back] call FUNC(setActive);
