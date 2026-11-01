#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_bootFail

Description:
    The database was required and did not answer. Say so, unmissably, and stop
    pretending the mission is configured.

    WHY REFUSING BEATS CARRYING ON. A mission whose config lives in the
    database has no arsenal, no nets, no roles and no ranks without it. Booting
    anyway gives a server full of people with no gear and no radios, and an
    admin working out over twenty minutes that the roster is empty because a
    connection string is wrong. One loud failure at boot costs a restart; a
    quiet one costs the session.

    WRITTEN TO THE .RPT, NOT JUST THE SCREEN. With `-autoInit` the mission
    starts with nobody watching - the server initialises it at startup rather
    than waiting for a player. An on-screen message nobody is there to read is
    not a failure report, so this goes to the log as a block that can be found
    by searching for PAC BOOT FAILED.

    IT DOES NOT END THE MISSION. Ending it would fight `-autoInit`, which would
    restart and fail again in a loop, and would take the server away from an
    admin trying to fix the setting. Instead GVAR(bootFailed) is set and
    published: the systems that would misbehave check it, and every client that
    joins is told why.

Parameters:
    0: Why <STRING> - what was tried and what happened, in words

Returns:
    Nothing

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_why", "the database did not answer", [""]]];

if (!isServer) exitWith {};

GVAR(bootFailed) = true;
GVAR(bootFailedWhy) = _why;
publicVariable QGVAR(bootFailed);
publicVariable QGVAR(bootFailedWhy);

private _unit = GVAR(settings) getOrDefault ["unitId", "?"];

// One block, findable by searching the .rpt for "PAC BOOT FAILED".
{
    diag_log text _x;
} forEach [
    "",
    "    +--------------------------------------------------------+",
    "    |  ####  #  #  ####  ####  ####      ####  ####  ####    |",
    "    |  #     #  #  #  #  #      ##       #  #  #  #  #       |",
    "    |  # ##  ####  #  #  ####   ##       ####  ####  #       |",
    "    |  #  #  #  #  #  #     #   ##       #     #  #  #       |",
    "    |  ####  #  #  ####  ####   ##       #     #  #  ####    |",
    "    |                                                        |",
    "    |      X X X   B O O T   F A I L E D   X X X             |",
    "    |        N O   D A T A B A S E ,  N O   C O N F I G      |",
    "    +--------------------------------------------------------+",
    "",
    "==============================================================",
    "  TAC//PAC BOOT FAILED - the mission is NOT configured",
    "==============================================================",
    format ["  unit id      : %1", _unit],
    format ["  what happened: %1", _why],
    "",
    "  This mission takes its config from the database - arsenal, nets,",
    "  roles, ranks. None of it was read, so nothing is set up.",
    "",
    "  Check, in this order:",
    "    1. Addon Options > JMSB - Mission & Admin > TAC//PAC Service > Database",
    "       (or GHOSTD_PACDB_URL / pacdb.json on the server)",
    "    2. That this server's public IP is on the database's access list.",
    "       The host's panel shows it, or ask the host.",
    "    3. That ghostd_pacdb_x64.dll / .so is loaded - the boot log above",
    "       says so if the address could not be handed to the extension.",
    "",
    "  To run anyway on this server's own config, turn OFF:",
    "    Addon Options > JMSB - Mission & Admin > TAC//PAC Service > Database required",
    "==============================================================",
    ""
];

[
    "3/6",
    format ["BOOT FAILED - %1. 'Database required' is on, so the mission has NOT been configured. See the block in the .rpt.", _why]
] call FUNC(bootLog);

// Everyone already in, and everyone who joins later (XEH_postInit reads the
// published variable), is told why rather than left guessing.
["TAC//PAC", format ["NOT CONFIGURED: %1. The database is required by this mission - tell an admin.", _why], [0.831, 0.267, 0.267, 1]]
    remoteExec ["jmfsb_notify_fnc_notify", 0];

ERROR_1("PAC BOOT FAILED - %1",_why);
