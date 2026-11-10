#include "script_component.hpp"

// THE REPORT (review L2). An admin command on the #jmfsb surface: registered on
// every machine, because the typer's machine looks it up and the server runs
// it; admins only, and the answer goes to the caller alone - it names where
// the leaders are, which nobody else should read. #jmfsbleaders is a shortcut
// to `#jmfsb leaders`.
["leaders", "who is left, where, and in what state", {
    private _txt = format ["side=%1 houses=%2 | %3", GVAR(asymSide), count GVAR(houses),
        GVAR(leaders) apply {
            _x params ["_u", "_h", "_s"];
            format ["%1:%2@h%3", ["?", name _u] select (!isNull _u), _s, _h]
        }];
    diag_log text format ["[jmfsb_leaders] %1", _txt];
    format ["LEADERS: %1", _txt]
}] call EFUNC(common,addDebugCommand);

if (hasInterface) then {
    ["jmfsbleaders", {
        ["#jmfsb leaders", player] call EFUNC(common,debugCommand);
    }, "all"] call CBA_fnc_registerChatCommand;
};

if (!isServer) exitWith {};

// THE MODULE IS THE ENABLE. This file only sets up state and the report
// command; FUNC(moduleController) is what arms the system, so a mission with
// no module placed gets nothing from this addon. GVAR(moduleUp) is declared in
// XEH_preInit, NOT here - see there for why.
// One record per leader: [unit, houseIndex, state, tier]. state is "up",
// "dead" or "captured". FINITE - this array never grows.
GVAR(leaders) = [];
GVAR(houses) = [];
GVAR(asymSide) = sideUnknown;
// The insurgents' faction when ALiVE is not loaded to name it (FUNC(start)).
GVAR(asymFaction) = "";
// leader index -> the house his intel currently points at. Set BEFORE he
// moves, so intel found in the old house points where he is going.
GVAR(nextHouse) = createHashMap;
