#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether the HACK app's SPOOF can be picked for the selected target: a
 * unit's net (a handset, or a vehicle carrying a set - FUNC(scanDevices)),
 * whose GPS the hack can walk off true, and jmfsb_ew loaded - its spoof
 * engine (jmfsb_ew_fnc_spoofNode) does the walking. Everything else about the
 * hack - who may run it, range, clock, fail and detection rolls - is the same
 * as a TAP on that net.
 *
 * Arguments:
 * 0: The hack session <HASHMAP>
 *
 * Return Value:
 * SPOOF is on offer <BOOL>
 *
 * Example:
 * [jmfsb_hacking_session] call jmfsb_hacking_fnc_canSpoof
 *
 * Public: Yes
 */

params [["_session", createHashMap, [createHashMap]]];

(_session getOrDefault ["kind", ""]) isEqualTo "unit" && !isNil QEFUNC(ew,spoofNode)
