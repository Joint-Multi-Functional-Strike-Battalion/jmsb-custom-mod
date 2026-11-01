#include "script_component.hpp"

// THE REPORT, admins only, answered to the caller alone (review R1: it was a
// CBA event any player could raise to print every battery's position in
// everyone's chat). On the #jmfsb surface: registered on every machine, because
// the typer's machine looks it up, and run on the server. #jmfsbaa is a
// shortcut to `#jmfsb aa`.
["aa", "air defence batteries and MANPAD teams, and where they are", {
    private _txt = format ["%1 batter(y/ies), %2 MANPAD team(s) | %3",
        count GVAR(sites), count GVAR(teams),
        GVAR(sites) apply {
            _x params ["_pos", "_side"];
            format ["%1@%2", _side, mapGridPosition _pos]
        }];
    diag_log text format ["[jmfsb_airdefence] %1", _txt];
    format ["AIR DEFENCE: %1", _txt]
}] call EFUNC(common,addDebugCommand);

if (hasInterface) then {
    ["jmfsbaa", {
        ["#jmfsb aa", player] call EFUNC(common,debugCommand);
    }, "all"] call CBA_fnc_registerChatCommand;
};

if (!isServer) exitWith {};

// THE MODULE IS THE ENABLE. This file only sets up state and the report
// command; FUNC(moduleController) is what arms the system, so a mission with no
// module placed gets nothing from this addon. GVAR(moduleUp) is declared in
// XEH_preInit, NOT here - see there for why.

// [centre, side] per site. NO object references: profiling deletes the hardware
// and ALiVE makes new objects later, so a site is a PLACE.
GVAR(sites) = [];
// the physical pieces, for the rearm loop - null entries are profiled or dead
GVAR(hardware) = [];
GVAR(teams) = [];
