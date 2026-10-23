#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: whether the local player reaches anyone on a net of his. A radio
 * net: any of his nodes has a path of quality above 0 to a peer on it; a
 * CALL: he reaches at least one other member on DATA. VEH and DIRECT always.
 * A net he is on but cannot reach is shown with a red outline, not hidden.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * Reachable <BOOL>
 *
 * Example:
 * ["C2"] call jmfsb_voice_fnc_reachable
 *
 * Public: No
 */

params [["_net", "", [""]]];

([_net] call FUNC(netQuality)) > 0
