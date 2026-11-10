#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_opordPost

Description:
    Posts the current OPORD to the C2 mailbox as an "opord" message, tagged
    with its id so anyone can find every message about it. Runs on the
    admin's machine FUNC(opordAsk) chose, through messaging's own submit -
    the same validation and the same server round trip as anything typed.

    THE PAYLOAD IS THE OPORD'S SIX SECTIONS, each section's fields joined
    with a blank line between, under the "opord" template's lines - see
    FUNC(registerTemplates) for the shape. The tacpad's PAC app is where the
    OPORD is READ; this is the notification that it exists, and the thread
    the METT-TC replies hang off.

Parameters:
    None

Returns:
    Whether it was sent <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

if (!hasInterface || {isNull player}) exitWith {false};
if (isNil "jmfsb_messaging_fnc_submit") exitWith {false};

private _id = GVAR(settings) getOrDefault ["currentOpord", ""];
private _opord = (GVAR(structure) getOrDefault ["opords", createHashMap]) getOrDefault [_id, createHashMap];
if (count _opord isEqualTo 0) exitWith {
    WARNING_1("currentOpord '%1' is not in the structure - nothing posted",_id);
    false
};

private _fnc_section = {
    params ["_name", "_fields"];
    private _sec = _opord getOrDefault [_name, createHashMap];
    private _parts = [];
    {
        private _v = _sec getOrDefault [_x, ""];
        if (_v isEqualType []) then {_v = _v joinString ", "};
        if (_v isNotEqualTo "") then {_parts pushBack _v};
    } forEach _fields;
    _parts joinString (endl + endl)
};

private _header = _opord getOrDefault ["header", createHashMap];
private _payload = [
    ["Header.A", ([_header getOrDefault ["id", ""], _header getOrDefault ["title", _id]] select {_x isNotEqualTo ""}) joinString " - "],
    ["Header.B", _header getOrDefault ["date", ""]],
    ["Situation.A", ["situation", ["overview", "enemy", "friendly", "civilTerrain"]] call _fnc_section],
    ["Mission.A", ["mission", ["mission", "execution"]] call _fnc_section],
    ["AdminLog.A", ["adminLogistics", ["admin", "logistics", "special", "armaConsiderations"]] call _fnc_section],
    ["CommandSignal.A", ["commandSignal", ["command", "signal"]] call _fnc_section],
    ["ROE.A", ["roe", ["roeText"]] call _fnc_section]
];

(["opord", _payload, ["B:C2"], "", "", ["OPORD:" + _id]] call jmfsb_messaging_fnc_submit) params ["_sent", "_why"];

if (_sent) then {
    INFO_1("OPORD %1 posted to C2",_id);
    // The server marks it posted only now (review L1).
    [player, true] remoteExecCall [QFUNC(opordAsk), 2];
} else {
    WARNING_2("OPORD %1 not posted: %2",_id,_why);
};

_sent
