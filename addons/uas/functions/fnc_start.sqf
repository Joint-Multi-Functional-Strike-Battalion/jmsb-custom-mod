#include "script_component.hpp"
/*
 * Author: YonV
 * Places the supply caches and starts the patrol and spotting ticks.
 *
 * Called by FUNC(moduleController) once ALiVE is up - never on its own. The
 * module is the enable, so a mission with no module never reaches here.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Example:
 * [] call jmfsb_uas_fnc_start
 */

if (!isServer) exitWith {};

[] call FUNC(placeCaches);

// planPatrols, NOT topUp. A per-frame handler is called with [args, handle],
// so wiring topUp here handed its params [["_side", sideUnknown, ...]] an
// empty ARRAY and it threw on every tick - the fleet was never topped up after
// the first plan, for a whole mission. planPatrols takes no arguments and is
// the per-tick planner; it calls topUp per side itself.
[LINKFUNC(planPatrols), UAS_PATROL_TICK, []] call CBA_fnc_addPerFrameHandler;
[LINKFUNC(spotSweep), UAS_SPOT_TICK, []] call CBA_fnc_addPerFrameHandler;
