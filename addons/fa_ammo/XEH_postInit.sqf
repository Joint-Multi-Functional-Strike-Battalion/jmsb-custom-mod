#include "script_component.hpp"

["CAManBase", "fired", {
    params ["_unit", "", "", "", "_ammo", "", "_proj"];
    // second name is the pre-side-prefix compat alias; Fired runs on every
    // machine, so only the shooter's tracks the round
    if (_ammo in ["FA_b_12G_Mk353_BRC", "FA_12G_Mk353_BRC"] && GVAR(enableBreaching) && {local _proj}) then {
        [_unit, _proj] call FUNC(breach);
    };
}] call CBA_fnc_addClassEventHandler;

// Add the "Future Ammunition" briefing to the local player's map Notes.
// The "unit" player event fires immediately for the current player and again
// on each unit change (respawn / unit switch), re-adding the diary since
// records live on the unit object.
if (hasInterface) then {
    ["unit", {
        params ["_unit"];
        _unit call FUNC(addDiary);
    }, true] call CBA_fnc_addPlayerEventHandler;
};
