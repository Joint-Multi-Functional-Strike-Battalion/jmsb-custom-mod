#include "script_component.hpp"
/*
 * Author: YonV
 * Starts watching the sender's own TIC thread for the contact ending (user,
 * 2026-11-02: "after contact a sitrep should be sent"). Called on his machine
 * when his TIC comes back filed (FUNC(contactTraffic)) - the TIC key, the map
 * panel and a card filled by hand alike, since all three are the same filed
 * card.
 *
 * CONTACT IS WHAT HIS GROUP DOES AND HAS DONE TO IT. One handler per
 * CONTACT_EVENTS on each of his group's units - a shot fired by one of them, a
 * shot fired near one of them, one of them hit, one of them suppressed - only
 * stamps the time; a new TIC from his group does the same (FUNC(contactTraffic)).
 * Nothing runs per frame: one quiet check is queued CONTACT_QUIET_S out and
 * queues itself again to the last stamp (FUNC(contactCheck)). Hit and
 * Suppressed fire only where the unit is local - his own man, his own AI -
 * and a remote man's own shots and the shots near him still count.
 *
 * ONE WATCH, THE NEWEST TIC. A second TIC of his replaces the first: the
 * handlers are taken off and put on again for the group as it is now.
 *
 * Arguments:
 * 0: His TIC thread <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["T0004"] call jmfsb_tacpad_fnc_contactArm
 *
 * Public: No
 */

params [["_threadId", "", [""]]];

if (_threadId isEqualTo "") exitWith {};

[] call FUNC(contactDrop);

GVAR(contactThread) = _threadId;

// The threads already in his index are old news; only one filed from now on
// can be a new TIC from his group.
GVAR(contactSeen) = ((missionNamespace getVariable [QEGVAR(messaging,index), []]) select {
    _x isEqualType createHashMap
}) apply {_x getOrDefault ["threadId", ""]};

{
    private _unit = _x;
    {
        private _id = _unit addEventHandler [_x, {
            GVAR(contactLast) = CBA_missionTime;
            if (GVAR(contactPrompted)) then {[] call FUNC(contactAgain)};
        }];
        GVAR(contactHandlers) pushBack [_unit, _x, _id];
    } forEach CONTACT_EVENTS;
} forEach (units group player);

[] call FUNC(contactAgain);
