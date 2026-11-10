#include "script_component.hpp"
/*
 * Author: YonV
 * The map closed. Drops every panel and stops the refresh loop.
 *
 * The controls die with the display, so this is not about deleting them - it is
 * about not holding references to dead controls and not leaving a per-frame
 * handler running against a display that is gone. That handler is the one that
 * would still be ticking an hour later.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

if (!hasInterface) exitWith {};

if (GVAR(tickPFH) != -1) then {
    [GVAR(tickPFH)] call CBA_fnc_removePerFrameHandler;
    GVAR(tickPFH) = -1;
};

{
    _y params ["_group"];
    if (!isNull _group) then {
        ctrlDelete _group;
    };
} forEach GVAR(open);

GVAR(open) = createHashMap;
GVAR(diaryOpen) = false;
