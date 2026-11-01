#include "script_component.hpp"
/*
 * Author: JMSB
 * The echo test's state, for the phone and the tablet to show: "" when the
 * extension is not loaded (offer nothing), "idle", "joining" (waiting for the
 * voice server's echo bot) or "live".
 *
 * Arguments:
 * None
 *
 * Return Value:
 * State <STRING>
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_echoState
 *
 * Public: Yes
 */

GVAR(echo)
