#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the local player on his squad's TEAM net - when he picks a role (user,
 * 2026-10-21: "players need to be set to their squad channel on role
 * selection"), as a fresh start and a respawn already do. Off Global first;
 * then the active net is cleared and FUNC(checkActive) lands him on TEAM, now
 * and again on the tick his new group's nets arrive.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * [] call jmfsb_voice_fnc_toTeam
 *
 * Public: Yes
 */

if (!GVAR(active) || {!hasInterface}) exitWith {false};

if (GVAR(globalOn)) then {[false] call FUNC(global)};
GVAR(activeNetId) = "";
GVAR(beforeCall) = "";
// The TEAM net may not be listed yet (the roster is a second behind a role
// pick); FUNC(checkActive) keeps looking for it this long.
GVAR(wantTeamUntil) = CBA_missionTime + TEAM_WAIT_S;
[] call FUNC(checkActive);
true
