#include "script_component.hpp"

[{
    if (!GVAR(loggingEnabled)) exitWith {};

    INFO("Friendly fire logging enabled");

    if (hasInterface) then {
        // On the CBA unit event, not a one-shot waitUntil: the Hit handler
        // rides the player OBJECT, and the object changes on respawn - bound
        // once, FF logging silently stopped after the first death.
        ["unit", {
            params ["_new", "_old"];
            if (!isNull _old && {!isNil QGVAR(ehId)}) then {
                _old removeEventHandler ["Hit", GVAR(ehId)];
            };
            if (isNull _new) exitWith {};
            INFO("Adding friendly fire EH");
            GVAR(ehId) = _new addEventHandler ["Hit", {
                params ["_target", "_shooter"];

                if (
                    !isPlayer _shooter
                    || {side group _target != side group _shooter
                    || _target isEqualTo _shooter}
                ) exitWith {};

                // The victim's own RPT, and the server's by remoteExec, where
                // the victim is the sender himself (review R1: it was a global
                // CBA event any client could raise to forge FF lines).
                [_target, _shooter, vehicle _shooter] call FUNC(log);
                if (!isServer) then {
                    [_target, _shooter, vehicle _shooter] remoteExecCall [QFUNC(log), SERVER_OWNER];
                };
            }];
        }, true] call CBA_fnc_addPlayerEventHandler;
    };
}] call EFUNC(common,runAfterSettingsInit);
