#include "script_component.hpp"
/*
 * Author: YonV
 * One burst reaches this player (client): the source is put on the jam
 * registry with its expiry, and the registry is applied at once. A source
 * already listed has its time refreshed, not extended - the cooldown
 * already limits how often a burst can come.
 *
 * Arguments:
 * 0: Source id <STRING>
 * 1: Seconds <NUMBER>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_id", "", [""]], ["_dur", 5, [0]]];
if (!hasInterface || _id isEqualTo "" || _dur <= 0) exitWith {};

GVAR(jamSources) set [_id, CBA_missionTime + _dur];
call FUNC(jamTick);
