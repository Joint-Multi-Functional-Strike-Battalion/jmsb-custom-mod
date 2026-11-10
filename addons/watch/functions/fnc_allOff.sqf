#include "script_component.hpp"
/*
 * Author: YonV
 * ALL OFF: every slot of every profile cleared - the world panels, the device
 * panel and the key hints go with them; each profile's onRemove runs, so the
 * server forgets contacts nobody else watches. The self-aid slot comes back
 * on the next tick if its setting is on.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_watch_fnc_allOff
 *
 * Public: Yes
 */

{
    private _onRemove = (GVAR(profiles) getOrDefault [_x, createHashMap]) getOrDefault ["onRemove", {}];
    {[_x # 0] call _onRemove} forEach _y;
    GVAR(slots) set [_x, []];
} forEach +GVAR(slots);
GVAR(current) = "";
