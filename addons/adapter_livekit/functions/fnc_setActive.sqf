#include "script_component.hpp"
/*
 * Author: JMSB
 * Hook "setActive": the voice core made a net the active one - what PTT 1
 * talks on. Always taken: the server has no channel to fail on. A held PTT 1
 * moves with it (FUNC(mic)).
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * true <BOOL>
 *
 * Example:
 * ["C2"] call jmfsb_adapter_livekit_fnc_setActive
 *
 * Public: No
 */

params [["_net", "", [""]]];

GVAR(activeNet) = _net;
[] call FUNC(mic);
true
