#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_publish

Description:
    Sends the roster to every client, as one flat readable array.

    CLIENTS READ, CLIENTS NEVER WRITE. This is the only direction player data
    travels outward. An edit goes the other way through remoteExec to a
    server-side function that re-checks who is asking - a client that could
    write the roster is a client that owns the roster.

    IT IS NOT THE STORE. Notes and saved loadouts stay on the server: a note is
    written by an admin ABOUT a player and is nobody else's business, and a
    loadout is several kilobytes per role per person that no roster row needs.
    What goes out is what a roster row and a record page draw.

    ONE VARIABLE, WHOLE, WHICH IS PHASE 1's ANSWER. The handoff puts deltas in
    phase 2 and says so; sending the lot on every change is wrong for sixty
    players and completely fine for the size a unit actually runs, and the shape
    that replaces it wants a client that already works to compare against.

    PUBLISHED ON CHANGE, NOT ON A TIMER. Nothing changes the roster except an
    admin action or a connect, and both call this. A poll would be a broadcast a
    second for a list that changes twice an evening. The heartbeat calls it
    only when the promotion-due list changed (FUNC(rosterTotals)).

    A client's roster handler re-applies only rank and skills
    (FUNC(reapplyLocal)); seeding, slotting and the kept loadout are first
    spawn and respawn work (FUNC(applyOnClient)), so a publish never resets
    anybody's gear.

Parameters:
    None

Returns:
    None

Author:
    YonV
---------------------------------------------------------------------------- */

if (!isServer) exitWith {};

private _out = [];

// Own attendance, all time, per player: [minutes, joins], so a client can show
// "time on" without ever holding the sessions. Totalled on the heartbeat by
// FUNC(rosterTotals), not here - the session list only grows.
private _totals = GVAR(rosterTotals);

{
    private _rec = _y;
    _out pushBack [
        _x,
        _rec getOrDefault ["name", ""],
        _rec getOrDefault ["rankId", ""],
        _rec getOrDefault ["roleId", ""],
        _rec getOrDefault ["groupId", ""],
        _rec getOrDefault ["statusId", ""],
        _rec getOrDefault ["skillIds", []],
        _rec getOrDefault ["awards", []],
        _rec getOrDefault ["updatedAt", ""],
        _totals getOrDefault [_x, [0, 0]],
        // the website's roster columns the row lacked (2026-09-09): the
        // operator id, and whether a Discord id is on file - the id itself
        // stays on the server
        _rec getOrDefault ["operatorId", ""],
        (_rec getOrDefault ["discordId", ""]) isNotEqualTo ""
    ];
} forEach GVAR(players);

// Sorted by name here rather than on every client's every redraw - the server
// does it once and forty machines do not each do it forty times a minute. The
// rows lead with the UID, which is the key and not the sort, so they are sorted
// through a name-first pair and unwrapped.
private _byName = _out apply { [toLower (_x # 1), _x] };
_byName sort true;
_out = _byName apply { _x # 1 };

GVAR(roster) = _out;
publicVariable QGVAR(roster);

// WHO IS DUE A PROMOTION, worked out on the server because FUNC(promotionPoints)
// reads GVAR(players), which a client does not have (2026-09-09). Kept by
// FUNC(rosterTotals) on the heartbeat, which walks every session per player.
private _due = +GVAR(promotable);

// how many have no Discord id on file - the website's "needs attention" row
private _noDiscord = 0;
{if ((_y getOrDefault ["discordId", ""]) isEqualTo "") then {_noDiscord = _noDiscord + 1}} forEach GVAR(players);

// The live tile's numbers, kept apart from the roster so the tile does not have
// to walk it. Phase 2 wants exactly this shape and calls it a summary struct.
GVAR(summary) = createHashMapFromArray [
    ["hash", GVAR(structureHash)],
    ["orphans", +GVAR(orphans)],
    ["readOnly", GVAR(readOnly)],
    ["savedAt", GVAR(savedAt)],
    ["backend", ["profile", "profile + service (pacdb)"] select GVAR(svcUp)],
    ["ready", GVAR(ready)],
    ["opord", GVAR(settings) getOrDefault ["currentOpord", ""]],
    ["players", count GVAR(players)],
    ["window", [] call FUNC(windowCurrent)],
    ["windowName", [[] call FUNC(windowCurrent)] call FUNC(windowName)],
    ["promotable", _due],
    // the website's dashboard tiles and "needs attention" rows the game had
    // no numbers for (2026-09-09): sessions, windows, who has no Discord id,
    // and what the database has said since boot (-1 = not asked yet)
    ["sessions", count GVAR(sessions)],
    ["windows", count GVAR(windows)],
    ["noDiscord", [_noDiscord, count GVAR(players)]],
    ["ticketsOpen", missionNamespace getVariable [QGVAR(ticketsOpen), -1]],
    ["applicationsNew", missionNamespace getVariable [QGVAR(applicationsNew), -1]],
    ["docs", missionNamespace getVariable [QGVAR(docsCount), 0]]
];
publicVariable QGVAR(summary);
// The archive only when it changed: it is every cached order, whole. Compared
// as text because its writers replace it or set into it in several places.
private _archive = str GVAR(opordArchive);
if (_archive isNotEqualTo GVAR(archiveSent)) then {
    GVAR(archiveSent) = _archive;
    publicVariable QGVAR(opordArchive);
};

// The host does not hear its own publicVariable - run its handlers by hand.
["roster"] call FUNC(hostRefresh);

TRACE_1("roster published",count _out);

nil
