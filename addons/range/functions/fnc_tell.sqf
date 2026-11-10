#include "..\script_component.hpp"
/*
 * Author: YonV
 * A range message to the shooter and every player within VICINITY of them.
 *
 * Arguments:
 * 0: Shooter <OBJECT>
 * 1: Text <STRING>
 * 2: Colour <ARRAY>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_text", "", [""]], ["_colour", NOTE_INFO, [[]]]];

private _to = allPlayers select {_x distance _unit < VICINITY};
_to pushBackUnique _unit;

[NOTE_TITLE, _text, _colour] remoteExecCall [QEFUNC(notify,notify), _to];
