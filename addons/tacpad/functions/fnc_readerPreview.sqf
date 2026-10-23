#include "script_component.hpp"
/*
 * Author: JMSB
 * One message as one short line - the preview under a list row's subject and
 * on the FLASH banner. The answers the card was filled with, in order, without
 * the line headers; a reply with no fields (ROGER, WILCO) is its own title.
 *
 * Arguments:
 * 0: Message <HASHMAP>
 * 1: Most characters to return <NUMBER> (optional, default READER_PREVIEW_CHARS)
 *
 * Return Value:
 * Preview <STRING>
 *
 * Example:
 * private _line = [_message] call jmfsb_tacpad_fnc_readerPreview
 *
 * Public: No
 */

params [["_msg", createHashMap, [createHashMap]], ["_max", READER_PREVIEW_CHARS, [0]]];

private _templateId = _msg getOrDefault ["templateId", ""];
private _body = [_templateId, _msg getOrDefault ["payload", []], false] call EFUNC(messaging,render);

// FUNC(render) writes a header, its answer and a blank line per filled line;
// with the blanks dropped, the answers are every second line.
private _lines = (_body splitString endl) select {trim _x isNotEqualTo ""};
private _values = [];
{
    if ((_forEachIndex mod 2) isEqualTo 1) then {_values pushBack trim _x};
} forEach _lines;

private _text = _values joinString " - ";
if (_text isEqualTo "") then {
    _text = ([_templateId] call EFUNC(messaging,template)) getOrDefault ["title", ""];
};

if (count _text > _max) then {
    _text = (_text select [0, _max - 3]) + "...";
};

_text
