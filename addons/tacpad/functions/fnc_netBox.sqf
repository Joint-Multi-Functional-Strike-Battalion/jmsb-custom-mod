#include "script_component.hpp"
/*
 * Author: YonV
 * The mailbox id a net name on the rail stands for.
 *
 * ONE RULE, ONE PLACE. This was written out by hand in the reader's stream
 * lookup, in the compose pane and in the net composer, and the three copies had
 * already drifted - which is how pressing a net in the rail could retitle the
 * compose pane while the message stayed addressed to the box it opened on. A
 * squad's net is a G: box, everything else the mission named is a B:, and ALL is
 * a VIEW rather than a net.
 *
 * ADDRESSABLE IS THE CALLER'S QUESTION. Reading ALL means "every box at once",
 * which is a stream and not an address, so it answers "". Addressing ALL has to
 * land somewhere real, so it falls back to the first mailbox the mission named -
 * the rule the compose pane and the net composer both already used.
 *
 * Arguments:
 * 0: Net name as the rail spells it <STRING>
 * 1: Fall back to a real box when the name is not addressable <BOOL> (optional, default false)
 *
 * Return Value:
 * Mailbox id - B:<name>, G:<groupId>, or "" <STRING>
 *
 * Example:
 * private _box = ["WRAITH", true] call jmfsb_tacpad_fnc_netBox
 *
 * Public: Yes
 */

params [["_net", "", [""]], ["_addressable", false, [false]]];

// The legacy key: older saved state can still hold SQUAD, which only ever meant
// your own group.
if (_net isEqualTo "SQUAD") exitWith {format ["G:%1", groupId (group player)]};

if (_net isEqualTo "" || _net isEqualTo "ALL") exitWith {
    if (_addressable) then {
        private _boxes = ((EGVAR(messaging,namedBoxes) splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};
        format ["B:%1", _boxes param [0, "HQ"]]
    } else {
        ""
    }
};

private _squads = [];
if (!isNil QEFUNC(messaging,squadNets)) then {
    _squads = [] call EFUNC(messaging,squadNets);
};

[format ["B:%1", _net], format ["G:%1", _net]] select (
    _net isEqualTo groupId (group player)
    || {_net in _squads}
)
