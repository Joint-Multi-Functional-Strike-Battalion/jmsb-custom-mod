#include "script_component.hpp"
/*
 * Author: JMSB
 * THE TRANSMISSION-LISTENER HOOK. EW's intercept and DF register here; RF
 * never knows what they do. Once per server tick each listener is called with
 * every emitting node:
 *
 *   [[id, object, position ASL, profile id, bands, TX dBm, side, tx, emcon,
 *     net ids, data], ...]
 *
 * data is the node's extra-data hashmap (jmfsb_rf_fnc_register /
 * jmfsb_rf_fnc_setState "data"), e.g. "intent". It is the registry's own: a
 * listener reads it and never writes it.
 *
 * A node emits while it is on (a MANET set beacons whether or not anybody
 * talks); tx says whether it is carrying traffic now.
 *
 * Arguments:
 * 0: Listener <CODE>
 *
 * Return Value:
 * Hook index <NUMBER>
 *
 * Example:
 * [{params ["_emitters"]}] call jmfsb_rf_fnc_addListener
 *
 * Public: Yes
 */

params [["_code", {}, [{}]]];

GVAR(listeners) pushBack _code
