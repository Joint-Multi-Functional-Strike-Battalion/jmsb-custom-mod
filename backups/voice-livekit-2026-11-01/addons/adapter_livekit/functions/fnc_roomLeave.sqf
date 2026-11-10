#include "script_component.hpp"
/*
 * Author: YonV
 * Leaves the mission's room: the extension disconnects, the mic is closed,
 * the mix forgotten. For the echo test, which needs the extension's one
 * session (FUNC(echo) rejoins after); the mission's end disconnects on its
 * own (XEH_postInit).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_roomLeave
 *
 * Public: No
 */

if (GVAR(state) in [ROOM_JOINING, ROOM_LIVE]) then {
    ["disconnect"] call FUNC(ext);
};
GVAR(state) = ROOM_IDLE;
GVAR(mic) = false;
GVAR(sent) = createHashMap;
TRACE_1("room left",GVAR(room));
