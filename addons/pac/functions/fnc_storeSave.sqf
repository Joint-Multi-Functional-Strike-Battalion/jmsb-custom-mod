#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_storeSave

Description:
    Writes the store to the server's profile - and, when the service is up,
    to the service - at most once every PAC_SAVE_DEBOUNCE seconds. It is
    written when something changed: a connect, a disconnect, an admin's
    edit, a window started or stopped, an import, the mission ending. A
    save the debounce held back leaves GVAR(dirty) set, and the heartbeat
    (XEH_postInit) writes it then.

    NOTHING IS WRITTEN BEFORE GVAR(storeReady) - the boot sets it once the
    store is loaded (FUNC(boot) step 6). Before that the in-memory store is
    empty, and a write would overwrite the real one.

    THE DEBOUNCE IS NOT AN OPTIMISATION, IT IS THE FEATURE. saveProfileNamespace
    serialises the whole profile and writes it to disk, on the main thread. An
    admin working down a roster - rank, then skills, then a note - is three
    writes of the entire store in as many seconds, and that is the frame hitch
    phase 2 is written to avoid. Marking dirty is free; writing is not.

    A FORCED SAVE IS FOR THE MOMENTS THAT MATTER: mission end, an op window
    closing, an import. Those are the points where losing the last thirty
    seconds would actually cost something, and there is no frame left to protect
    anyway.

    IT REFUSES TO WRITE OVER A NEWER STORE. If FUNC(storeLoad) found a
    schemaVersion from the future it set GVAR(readOnly), and this respects it -
    a build that cannot read the store properly must not be the one that
    rewrites it.

    THE DATABASE IS WRITTEN ONLY WHEN ASKED. Passing the store to the service
    is off by default and turned on by exactly four callers: the SAVE button
    (FUNC(adminSave)), a player's logon and logoff (FUNC(sessionStart),
    FUNC(sessionEnd) - their play time), and the mission-end commit
    (XEH_postInit's "Ended"). Everything else - the boot's read-back, a rank
    edited in the panel, a player picking a role in game - writes the local
    profile only and never the database (user, 2026-09-05: "no write on boot,
    no write any time unless a button is pushed; updating play time is the only
    exception ... save to db on player logon and logoff" - the boot re-writing
    the store it had just read is what wiped the database). And never before
    READY - see the service block below.

Parameters:
    0: Force the write, ignoring the debounce <BOOL> (optional, default false)
    1: Also write the database, not just the profile <BOOL> (optional, default
       false - profile only)

Returns:
    Whether it wrote <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_force", false, [false]], ["_toService", false, [false]]];

if (!isServer) exitWith {false};

// NOTHING BEFORE THE STORE IS LOADED. Until the boot sets storeReady the
// in-memory store is preInit's empty one; writing it would blank the profile
// and its meta, so the lost-store check could not catch it.
if !(GVAR(storeReady)) exitWith {
    TRACE_1("store not loaded yet - not writing",_force);
    false
};

GVAR(dirty) = true;

if (GVAR(readOnly)) exitWith {
    WARNING("store is read-only - not writing");
    false
};

private _last = GVAR(lastSave);

if (!_force && {(diag_tickTime - _last) < PAC_SAVE_DEBOUNCE}) exitWith {
    // Nothing is lost by not writing now: the record is already in the runtime
    // hashmap and the next save takes it. What would be lost is the frame.
    false
};

GVAR(lastSave) = diag_tickTime;
GVAR(dirty) = false;

GVAR(meta) set ["lastSave", [] call FUNC(stamp)];
GVAR(meta) set ["players", count GVAR(players)];

profileNamespace setVariable [PAC_KEY_PLAYERS, GVAR(players)];
profileNamespace setVariable [PAC_KEY_SESSIONS, GVAR(sessions)];
profileNamespace setVariable [PAC_KEY_WINDOWS, GVAR(windows)];
profileNamespace setVariable [PAC_KEY_META, GVAR(meta)];
profileNamespace setVariable [PAC_KEY_OPORDS, GVAR(opordArchive)];
profileNamespace setVariable [PAC_KEY_STRUCTURE, GVAR(structureEdited)];
profileNamespace setVariable [PAC_KEY_LOG, GVAR(log)];

saveProfileNamespace;
GVAR(savedAt) = [] call FUNC(stamp);

// THE SERVICE, ONLY WHEN THE CALLER ASKED FOR IT (the SAVE button, a player's
// logon and logoff, mission end) AND it is up AND THE BOOT IS DONE: the same
// JSON the export gives, pushed through the extension on its own thread; the
// callback reports the outcome (XEH_postInit). A profile write is local and
// cheap and safe; a database write is neither, and must be deliberate.
//
// WHY READY: between boot step 3 (the service answers, svcUp goes true) and
// step 5 (the store is read back from the database) the in-memory store is
// the profile copy - possibly smaller than the database. A logon in that
// window (the host's own, always) must not push that copy over the real
// store. Before READY nothing writes the database; the session row is in
// memory and the next write carries it.
if (_toService && GVAR(svcUp) && {missionNamespace getVariable [QGVAR(ready), false]}) then {[] call FUNC(svcSave)};

TRACE_2("store written",count GVAR(players),count GVAR(sessions));

true
