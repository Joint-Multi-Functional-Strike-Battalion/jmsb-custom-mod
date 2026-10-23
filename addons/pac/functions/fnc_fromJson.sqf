#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_fromJson

Description:
    JSON text back into a value: objects become hashmaps, arrays arrays,
    null becomes nil (an array slot that was null is dropped; a hashmap value
    that was null is not set). The inverse of FUNC(toJson), and tolerant of
    anything else that writes standard JSON.

    WORKS ON CHARACTER CODES, NOT SUBSTRINGS. toArray once, then an index
    over the numbers: `select [i, 1]` on a 100 KB string is a copy per
    character and an import of a real store would take seconds. This takes a
    blink.

    NO `while` LOOPS (2026-10-19). The service read parses unscheduled now
    (FUNC(svcLoad)), and an unscheduled `while` stops after 10,000 turns
    without a word - a 27 KB logistics script is one string of 27,000
    characters and would have come back cut short. Every loop here is a
    `for ... from ... to` bounded by the text's length, which has no such cap.

    A PARSE ERROR RETURNS [nil, false, where]. It never throws, because the
    text came off an admin's clipboard and the right answer to a stray
    character is a message, not a script error.

Parameters:
    0: JSON <STRING>

Returns:
    [value, ok, error position] <ARRAY>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_text", "", [""]]];

private _c = toArray _text;
private _n = count _c;
private _i = 0;
private _err = -1;

// character codes this reads by
#define CH_QUOTE 34
#define CH_BACKSLASH 92
#define CH_LBRACE 123
#define CH_RBRACE 125
#define CH_LBRACKET 91
#define CH_RBRACKET 93
#define CH_COLON 58
#define CH_COMMA 44
#define CH_MINUS 45

private _fnc_skip = {
    for "_j" from _i to (_n - 1) do {
        if !((_c # _j) in [32, 9, 10, 13]) exitWith {};
        _i = _j + 1;
    };
};

private _fnc_fail = {
    if (_err < 0) then {_err = _i};
    nil
};

// A string is copied a STRETCH at a time - everything between two escapes in
// one `append` - rather than one pushBack per character.
private _fnc_string = {
    // on the opening quote
    private _from = _i + 1;
    private _out = [];
    private _ok = false;
    private _run = _from;       // where the current stretch without an escape began
    private _used = -1;         // the last index an escape has already consumed
    for "_j" from _from to (_n - 1) do {
        if (_j <= _used) then {continue};
        private _ch = _c # _j;
        if (_ch isEqualTo CH_QUOTE) exitWith {
            _out append (_c select [_run, _j - _run]);
            _i = _j + 1;
            _ok = true;
        };
        if (_ch isEqualTo CH_BACKSLASH) then {
            _out append (_c select [_run, _j - _run]);
            private _esc = _c param [_j + 1, 0];
            _used = _j + 1;
            switch (_esc) do {
                case 110: {_out pushBack 10};        // n
                case 114: {_out pushBack 13};        // r
                case 116: {_out pushBack 9};         // t
                case 98:  {_out pushBack 8};         // b
                case 102: {_out pushBack 12};        // f
                case 117: {                          // uXXXX
                    private _hex = toLower toString (_c select [_j + 2, 4]);
                    private _code = 0;
                    {
                        _code = _code * 16 + ("0123456789abcdef" find (toString [_x]));
                    } forEach toArray _hex;
                    _out pushBack _code;
                    _used = _j + 5;
                };
                default {_out pushBack _esc};        // " \ / and anything else literal
            };
            _run = _used + 1;
        };
    };
    if (!_ok) exitWith {_i = _n; call _fnc_fail};
    toString _out
};

private _fnc_number = {
    private _start = _i;
    for "_j" from _i to (_n - 1) do {
        if !((_c # _j) in [CH_MINUS, 43, 46, 69, 101, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57]) exitWith {};
        _i = _j + 1;
    };
    parseNumber toString (_c select [_start, _i - _start])
};

// true, false, null. `null` is nil, and a nil cannot be carried in a
// parameter without reading as undefined (the first in-game run logged
// "Undefined variable _result" once per null in the documents), so the
// value is picked by the word.
private _fnc_literal = {
    params ["_word"];
    private _len = count toArray _word;
    if (toString (_c select [_i, _len]) isEqualTo _word) exitWith {
        _i = _i + _len;
        switch (_word) do {
            case "true": {true};
            case "false": {false};
            default {nil};
        };
    };
    call _fnc_fail
};

private _fnc_value = {
    call _fnc_skip;
    if (_i >= _n) exitWith {call _fnc_fail};
    private _ch = _c # _i;

    switch (true) do {
        case (_ch isEqualTo CH_QUOTE): {call _fnc_string};
        case (_ch isEqualTo CH_LBRACE): {
            _i = _i + 1;
            private _map = createHashMap;
            call _fnc_skip;
            if ((_c param [_i, -1]) isEqualTo CH_RBRACE) exitWith {_i = _i + 1; _map};
            private _done = false;
            // bounded by the text: there cannot be more members than characters
            for "_member" from 0 to _n do {
                if (_done || _err >= 0) exitWith {};
                call _fnc_skip;
                if ((_c param [_i, -1]) isNotEqualTo CH_QUOTE) exitWith {call _fnc_fail};
                private _k = call _fnc_string;
                if (_err >= 0) exitWith {};
                call _fnc_skip;
                if ((_c param [_i, -1]) isNotEqualTo CH_COLON) exitWith {call _fnc_fail};
                _i = _i + 1;
                private _v = call _fnc_value;
                if (_err >= 0) exitWith {};
                if (!isNil "_v") then {_map set [_k, _v]};
                call _fnc_skip;
                switch (_c param [_i, -1]) do {
                    case CH_COMMA: {_i = _i + 1};
                    case CH_RBRACE: {_i = _i + 1; _done = true};
                    default {call _fnc_fail};
                };
            };
            if (_err >= 0) exitWith {nil};
            _map
        };
        case (_ch isEqualTo CH_LBRACKET): {
            _i = _i + 1;
            private _arr = [];
            call _fnc_skip;
            if ((_c param [_i, -1]) isEqualTo CH_RBRACKET) exitWith {_i = _i + 1; _arr};
            private _done = false;
            for "_element" from 0 to _n do {
                if (_done || _err >= 0) exitWith {};
                private _v = call _fnc_value;
                if (_err >= 0) exitWith {};
                if (!isNil "_v") then {_arr pushBack _v};
                call _fnc_skip;
                switch (_c param [_i, -1]) do {
                    case CH_COMMA: {_i = _i + 1};
                    case CH_RBRACKET: {_i = _i + 1; _done = true};
                    default {call _fnc_fail};
                };
            };
            if (_err >= 0) exitWith {nil};
            _arr
        };
        case (_ch isEqualTo 116): {["true"] call _fnc_literal};
        case (_ch isEqualTo 102): {["false"] call _fnc_literal};
        case (_ch isEqualTo 110): {["null"] call _fnc_literal};
        case (_ch isEqualTo CH_MINUS || {_ch >= 48 && _ch <= 57}): {call _fnc_number};
        default {call _fnc_fail};
    };
};

private _value = call _fnc_value;
call _fnc_skip;
if (_err < 0 && _i < _n) then {_err = _i};      // trailing rubbish

if (_err >= 0) exitWith {[nil, false, _err]};
[_value, true, -1]
