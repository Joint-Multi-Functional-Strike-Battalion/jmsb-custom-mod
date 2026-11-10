#include "script_component.hpp"
/*
 * Author: YonV
 * Who a mailbox delivers to right now. Membership is derived every time rather
 * than stored, because a player changes group mid-mission and a stored member
 * list would still be mailing their old squad an hour later.
 *
 * A shared mailbox delivers to nobody. That is not an oversight - it is what a
 * filing box is. The report is filed and shows up in the index of everyone who
 * can see that box; it does not ring a phone.
 *
 * Arguments:
 * 0: Box id <STRING>
 *
 * Return Value:
 * Players to deliver to <ARRAY>
 *
 * Example:
 * private _who = ["G:Alpha 1-2"] call jmfsb_messaging_fnc_srvMembers
 *
 * Public: No
 */

params [["_boxId", "", [""]]];

private _prefix = _boxId select [0, 2];
private _rest = _boxId select [2];

switch (_prefix) do {
    case "P:": {
        allPlayers select {alive _x && {getPlayerUID _x == _rest}}
    };
    case "G:": {
        allPlayers select {alive _x && {groupId (group _x) == _rest}}
    };
    default {
        // Explicit uids can still be added to a shared box by a mission script;
        // roles are read off the unit the same way the rest of the mod does.
        private _box = GVAR(boxes) getOrDefault [_boxId, createHashMap];
        private _uids = _box getOrDefault ["uids", []];
        private _roles = _box getOrDefault ["roles", []];

        allPlayers select {
            private _unit = _x;
            alive _unit && {
                getPlayerUID _unit in _uids || {_roles findIf {_unit getVariable [_x, false]} >= 0}
            }
        }
    };
};
