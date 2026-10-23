#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: the server sent this man's EW slice (FUNC(publish) has the
 * layout). Kept as GVAR(mine) - the transport variable on a listen server is
 * the server's own and is overwritten for every other client - and
 * announced, so an open EW app redraws.
 *
 * Arguments:
 * 0: Variable name (unused) <STRING>
 * 1: Slice <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * QGVAR(slice) addPublicVariableEventHandler {_this call jmfsb_ew_fnc_receiveSlice}
 *
 * Public: No
 */

params [["_name", "", [""]], ["_slice", [], [[]]]];

GVAR(mine) = _slice;
[QGVAR(sliceChanged), []] call CBA_fnc_localEvent;
