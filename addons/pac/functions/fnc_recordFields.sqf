#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_recordFields

Description:
    THE ONE TABLE of a player record's keys and their empty values - the
    operator record. FUNC(record) seeds a new record from it and
    FUNC(recordUpgrade) fills the keys an older record lacks, so every
    record has every key and no reader has to guard for a field that
    appeared later.

        identity     name (the Arma profile name, refreshed on connect),
                     operatorId (OP-nnnnn, given once), milsimName (the
                     name the unit calls them - "Cpl J. Miller"), discordId,
                     email (OPTIONAL, given by the player themselves on the
                     web manager - never asked for in game, never public),
                     enlistedAt (YYYY-MM-DD, the day the unit first saw them)
        service      rankId, promotedAt (the day the rank last changed),
                     clearance (what the unit lets them do - free text),
                     statusId (duty status)
        orbat        company (free text), groupId (the squad), roleId (the
                     billet), reportsTo (an operator id, or a name)
        logs         skillIds (held now), qualifications [[skillId, name,
                     dateEarned]] (ever granted), awards [[id, date, by,
                     citation]], excused [windowId] (absences an admin
                     excused), adminActions [[LOG-n, type, date, byUid,
                     byName, notes]], notes [[date, by, text]],
                     training [[date, by, text]] (courses held, back-datable),
                     ranges [[date, range, mode, detail, hits, shown,
                     seconds]] (shooting-range runs, jmfsb_range - the last
                     PAC_RANGE_KEEP of each range)
        the rest     loadouts, updatedAt, serverId

    The pay grade is the RANK's (structure ranks >> payGrade), the platoon
    is the ORBAT's, attendance is counted off the sessions - none of those
    are written on the record. FUNC(operatorJson) puts the lot together.

Parameters:
    None

Returns:
    [[key, empty value], ...] <ARRAY>

Author:
    YonV
---------------------------------------------------------------------------- */

[
    ["name", ""],
    ["operatorId", ""],
    ["milsimName", ""],
    ["discordId", ""],
    ["email", ""],
    ["enlistedAt", ""],
    ["rankId", ""],
    ["promotedAt", ""],
    ["clearance", ""],
    ["statusId", ""],
    ["company", ""],
    ["groupId", ""],
    ["roleId", ""],
    ["reportsTo", ""],
    ["skillIds", []],
    ["qualifications", []],
    ["awards", []],
    ["excused", []],
    ["adminActions", []],
    ["notes", []],
    ["training", []],
    ["ranges", []],
    ["loadouts", createHashMap],
    ["updatedAt", ""],
    ["serverId", ""]
]
