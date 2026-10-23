#include "script_component.hpp"
/*
 * Author: JMSB
 * The colour round a net chip - the net's state (user, 2026-10-21: "put net
 * state as a color around the net chips"). One answer for the walking view's
 * net row and the tablet's, from a FUNC(overlayNets) entry:
 *
 *   RING                 the alert colour, a call ringing
 *   muted                dim
 *   quality >= GOOD      green (NET_QUALITY_GOOD, jmfsb_voice_fnc_netQuality)
 *   quality above 0      amber - reachable but weak or jammed
 *   0                    red - on the net, no route
 *
 * Arguments:
 * 0: A FUNC(overlayNets) entry <ARRAY>
 *
 * Return Value:
 * Colour RGBA <ARRAY>
 *
 * Example:
 * [_entry] call jmfsb_devices_fnc_netOutline
 *
 * Public: No
 */

params [["_entry", [], [[]]]];

_entry params ["", "", "", "", ["_reach", false, [false]], "", ["_muted", false, [false]], ["_kind", "", [""]], ["_quality", -1, [0]]];
if (_quality < 0) then {_quality = parseNumber _reach};

switch (true) do {
    case (_kind isEqualTo NET_KIND_RING): {COLOUR_ALERT};
    case (_muted): {COLOUR_DIM};
    case (_quality >= NET_QUALITY_GOOD): {COLOUR_NET_OK};
    case (_quality > 0): {COLOUR_WARN};
    default {COLOUR_NET_BAD};
}
