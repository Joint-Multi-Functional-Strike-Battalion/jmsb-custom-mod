#include "script_component.hpp"
/*
 * Author: YonV
 * Is this body worth searching, and can this player reach it?
 *
 * Arguments:
 * 0: The body <OBJECT>
 * 1: The searcher <OBJECT>
 *
 * Return Value:
 * Show the action <BOOL>
 *
 * Public: No
 */

params [["_body", objNull, [objNull]], ["_player", objNull, [objNull]]];

!alive _body
&& {_body getVariable [QGVAR(bodyIntel), false]}
&& {alive _player}
