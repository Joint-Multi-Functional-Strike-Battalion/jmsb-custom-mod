#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the RTO nets as rows, published when they changed. The rows go out
 * as jmfsb_voice_customPub (public, JIP-kept) and into this machine's own
 * plan at once (FUNC(planRefresh)); every client's planRefresh picks them up
 * within its second and raises jmfsb_voice_netsChanged as it does for any
 * plan change.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Published - false when nothing changed <BOOL>
 *
 * Example:
 * [] call jmfsb_voice_fnc_srvNetPublish
 *
 * Public: No
 */

if (!isServer) exitWith {false};

private _rows = (keys GVAR(customNets)) apply {[_x] + (GVAR(customNets) get _x)};
_rows sort true;
if (_rows isEqualTo GVAR(customPub)) exitWith {false};

GVAR(customPub) = _rows;
publicVariable QGVAR(customPub);
[] call FUNC(planRefresh);
true
