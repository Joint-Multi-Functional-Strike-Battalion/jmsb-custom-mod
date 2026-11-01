#include "script_component.hpp"

// A FORCED RESPAWN IS NO LONGER A CBA EVENT (review S7): a client asks the
// server by remoteExec (FUNC(forceRespawnRequest), admins and Zeus only) and
// the server tells the dead by remoteExec (FUNC(forceLocal)).

if (hasInterface) then {
    // Save equipment event if anyone wanted to save it by himself at any time
    [QGVAR(saveEquipment), {
        GVAR(savedEquipment) = getUnitLoadout player;
    }] call CBA_fnc_addEventHandler;

    // Save initial equipment
    [{alive player}, {
        [QGVAR(saveEquipment)] call CBA_fnc_localEvent;
    }] call CBA_fnc_waitUntilAndExecute;

    // Respawn on/off and a new delay come from the server by remoteExec
    // (FUNC(enable), FUNC(disable), FUNC(adjustTimeLocal)), not by CBA events
    // any client could raise (review S7).

    [] call FUNC(addZeusModules);
};
