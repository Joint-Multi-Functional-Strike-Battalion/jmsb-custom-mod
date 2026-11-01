#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_applyOnClient

Description:
    Puts the player's own PAC rank and skills on their unit, from the roster the
    server published.

    NO ROUND TRIP. The client already holds the roster - FUNC(publish) sends it
    to everybody on every change - so the player's own row is read off that and
    applied locally. Asking the server for a record it has just broadcast would
    be a second message for the same answer, and it would arrive after the
    respawn it was meant for.

    RUNS ON SPAWN AND ON RESPAWN ONLY (and from the groups addon's role
    setup). Seeding, slotting and the kept loadout are spawn work: run on
    every publish they reset everyone's gear whenever anyone joined. A
    publish runs FUNC(reapplyLocal) instead - rank and skills - which is how
    an admin's edit reaches a man already in the field. The one exception:
    a publish that brings this player's row for the first time in this life
    (he spawned before he was on the roster) runs this, once - the unit's
    GVAR(spawnApplied) flag says whether it has.

    PAC IS THE SOURCE OF TRUTH FOR SKILLS. What is applied is the PAC
    assignment and only that; the roles no longer set skills (the groups addon
    skips every name PAC owns - see FUNC(managedNames)), and a record's first
    skills are seeded from the role once (FUNC(seedFromUnit)).

Parameters:
    None

Returns:
    Whether a record was found and applied <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

if (!hasInterface) exitWith {false};
if (isNull player || {!alive player}) exitWith {false};
if !(missionNamespace getVariable [QGVAR(ready), false]) exitWith {false};   // the boot gate - see whenReady

private _uid = [player] call FUNC(uid);
private _row = (missionNamespace getVariable [QGVAR(roster), []]) select {(_x # 0) isEqualTo _uid};

if (_row isEqualTo []) exitWith {false};

(_row # 0) params ["", "", "_rankId", "", "", "", "_skillIds"];

// this life has had its spawn work; a respawn is a new unit without the flag
player setVariable [QGVAR(spawnApplied), true];

[player, _rankId] call FUNC(applyRank);
[player, _skillIds] call FUNC(applySkills);

// THE SERVER DOES THE SLOTTING AND HOLDS THE LOADOUTS. Both are asked for
// here rather than done here: the slot table is the server's, and the kept
// loadout is on the record, which clients never see whole. autoSlot only
// matters before the player has a role; the loadout goes on after the role's
// own default, which is the order the groups addon's hook gives us.
// An empty rank or role on the record is filled from what the mission gave
// the player - see FUNC(seedFromUnit). Rank is sent from here because setRank
// is local to this machine and the server may still hold the mission's default.
[player, rank player, player getVariable ["YMF_role", ""], groupId group player] remoteExec [QFUNC(seedFromUnit), 2];

if ((player getVariable ["YMF_oldrole", ""]) isEqualTo "") then {
    [player] remoteExec [QFUNC(autoSlot), 2];
} else {
    [player] remoteExec [QFUNC(loadoutSend), 2];
};

// And whether this is the admin who posts the OPORD - the server decides.
[player] remoteExec [QFUNC(opordAsk), 2];

TRACE_2("PAC applied on client",_rankId,count _skillIds);

true
