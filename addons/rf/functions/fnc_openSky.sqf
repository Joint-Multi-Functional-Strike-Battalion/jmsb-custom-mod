#include "script_component.hpp"
/*
 * Author: JMSB
 * THE OPEN-SKY CHECK for a SAT terminal: one ray straight up from the antenna,
 * SKY_CHECK_M long. Anything it meets - a roof, a bridge, a hangar - blocks
 * the dish. The node's own object (and the vehicle a man sits in) is not in
 * the way. Cheap, but still a ray: jmfsb_rf_fnc_tick caches it per node and
 * re-casts it only on the static tick or when the node moved, never per frame.
 *
 * Arguments:
 * 0: Node object <OBJECT>
 * 1: Antenna position ASL (jmfsb_rf_fnc_nodePos) <ARRAY>
 *
 * Return Value:
 * The sky is open above it <BOOL>
 *
 * Example:
 * [_relay, [_relay] call jmfsb_rf_fnc_nodePos] call jmfsb_rf_fnc_openSky
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]], ["_pos", [0, 0, 0], [[]], 3]];

private _up = _pos vectorAdd [0, 0, SKY_CHECK_M];
(lineIntersectsSurfaces [_pos, _up, _obj, objectParent _obj, true, 1, "GEOM", "NONE"]) isEqualTo []
