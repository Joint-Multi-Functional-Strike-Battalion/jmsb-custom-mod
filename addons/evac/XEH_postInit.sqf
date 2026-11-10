#include "script_component.hpp"

// ACM BRINGS ITS OWN EVACUATION - ACM_evacuation, litters and all - so with it
// loaded this system stands down entirely (user, 2026-10-08: "with acm loaded
// we need to disable our medivac system"): no server handler, no casualty
// clone, and FUNC(canConvert) keeps the action off the menu. The setting
// stays visible; it has nothing to switch on.
if (missionNamespace getVariable [QEGVAR(patches,usesACM), false]) exitWith {
    INFO("ACM loaded - medic evac stands down");
};

// --- server: the evac itself is FUNC(evacServer), reached by remoteExec from
// FUNC(convert) so the server knows which medic sent it and checks him. It
// was a CBA server event, which any client could raise to full-heal anyone
// anywhere (review S6). FUNC(canConvert) stands it down with ACM loaded.

// --- everywhere: a marked casualty AI can never stay awake --------------------
// ace_unconscious fires on every consciousness change with [_unit, _active] where
// _active is true when the unit goes DOWN and false when it wakes. If one of our
// casualties woke (treated to stable vitals, epinephrine, spontaneous), put it
// straight back under. Death is never blocked, so it is still fully mortal.
["ace_unconscious", {
    params ["_unit", "_active"];
    if (_active) exitWith {};
    if !(local _unit) exitWith {};
    if !(_unit getVariable [QGVAR(isCasualtyAI), false]) exitWith {};
    if !(alive _unit) exitWith {};

    [{
        params ["_unit"];
        if (alive _unit && {_unit getVariable [QGVAR(isCasualtyAI), false]}) then {
            [_unit, true] call ace_medical_fnc_setUnconscious;
        };
    }, [_unit], 0.1] call CBA_fnc_waitAndExecute;
}] call CBA_fnc_addEventHandler;
