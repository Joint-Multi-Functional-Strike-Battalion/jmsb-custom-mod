#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_adminSave

Description:
    SAVE on the admin page: force-writes the store to every backend now -
    the profile, and the service when one is up - past the debounce, and
    re-publishes the roster so every client (the edited player included)
    reapplies rank and skills at once. Server only, admin-checked.

    WHY, WHEN EDITS ALREADY SAVE. Each edit (a rank combo, a skill tick)
    writes through FUNC(adminSet), but the disk write is debounced thirty
    seconds so a run down the roster is one write, not thirty. SAVE is the
    "I am done, put it down now" button: it makes the last edits durable
    immediately and confirms it, rather than an admin wondering whether the
    change stuck (user, 2026-09-05).

Parameters:
    0: Caller <OBJECT>

Returns:
    Whether it wrote <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]]];

if (!isServer) exitWith {false};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {false};

private _green = [0.4, 0.702, 0.4, 1];
private _red = [0.831, 0.267, 0.267, 1];

if (GVAR(readOnly)) exitWith {
    ["TAC//PAC", "Store is read-only - not saved.", _red] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
    false
};

// THE ONE PLACE A HUMAN COMMITS TO THE DATABASE. The second argument turns the
// service write on - this button, and mission end for play time, are the only
// two callers that do (user, 2026-09-05: "only a save button press should write").
private _wrote = [true, true] call FUNC(storeSave);
[] call FUNC(publish);      // re-broadcast the roster -> every client reapplies

// Hoisted: a comma inside a macro argument reads as an argument separator, so
// the getOrDefault array cannot sit inside INFO_3.
private _backend = GVAR(summary) getOrDefault ["backend", "profile"];
private _count = count GVAR(players);

["TAC//PAC", format ["Saved - %1 player(s) written to %2, roster reapplied.", _count, _backend], _green] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
INFO_3("%1 forced a save: %2 player(s), backend %3",name _caller,_count,_backend);

_wrote
