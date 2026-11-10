#include "script_component.hpp"
/*
 * Author: YonV
 * The engineer's eye (design engineer.threats): every mine or explosive within
 * the detect range (server setting) that he did not lay himself is revealed
 * to his side on the map and becomes a threat contact - boxed through the
 * goggles, tracked on the map, seen by friendlies by the same line-of-sight
 * rule as recon. No detector needed. Once a second, engineers only.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_watch_fnc_threatScan
 *
 * Public: No
 */

if (!alive player || {!([player] call FUNC(isEngineer))}) exitWith {};

private _own = getAllOwnedMines player;
{
    if (_x in GVAR(threatsSent) || {_x in _own}) then {continue};
    if ((player distance _x) > GVAR(detectRange)) then {continue};
    (side group player) revealMine _x;
    GVAR(threatsSent) pushBack _x;
    [QGVAR(contactAdd), [_x, "threat", player]] call CBA_fnc_serverEvent;
} forEach allMines;
GVAR(threatsSent) = GVAR(threatsSent) select {!isNull _x};
