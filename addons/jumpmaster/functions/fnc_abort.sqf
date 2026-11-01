#include "script_component.hpp"
/*
 * Author: JMSB
 * ABORT: the leader stops the passes. The aircraft holds over the drop zone
 * while anyone is still aboard - each man exits himself - and leaves once
 * the cabin is empty (FUNC(srvAbort)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_jumpmaster_fnc_abort
 *
 * Public: No
 */

// By remoteExec, so the server knows who sent it (review S7).
[call CBA_fnc_currentUnit] remoteExecCall [QFUNC(srvAbort), SERVER_OWNER];
