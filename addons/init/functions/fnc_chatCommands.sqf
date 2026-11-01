#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A -- Tinkered with by YonV
 * This function handle all our custom chat commands.
 * Every command is admin only (admin panel whitelist - config_admins.hpp).
 *
 * #attendance  - prints attendance to your RPT log
 * #exportranks - copies the live ranks as a config_ranks.hpp block to clipboard + chat + RPT
 *
 * Example:
 * call jmfsb_init_fnc_ChatCommands
 *
 * Public: No
 */

["attendance", {
    if !([player] call admp_fnc_isAdmin) exitWith {["Chat Command", "#attendance is admin only.", NOTE_BAD] call JMFSBFUNC(notify,notify)};
    // The server checks the sender itself (review S7).
    [] remoteExecCall [QFUNC(srvAttendance), SERVER_OWNER];
}] call CBA_fnc_registerChatCommand;

["exportranks", {
    if !([player] call admp_fnc_isAdmin) exitWith {["Chat Command", "#exportranks is admin only.", NOTE_BAD] call JMFSBFUNC(notify,notify)};
    call EFUNC(players,exportRanks);
}] call CBA_fnc_registerChatCommand;
