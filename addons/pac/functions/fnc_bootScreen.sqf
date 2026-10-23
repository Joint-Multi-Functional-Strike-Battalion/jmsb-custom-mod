#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_bootScreen

Description:
    The client's boot overlay - the mark, a progress bar, and the boot as a
    CHECKLIST: the six steps with a box each, ticked as the server reports
    them, and under the database step every document the read is asking
    for, ticked as it lands - held until the unit is READY, then faded.
    Spawned on every client from XEH_postInit.

    IT DOES NOT FLASH ON A FAST BOOT. A profile-only mission is READY almost
    at once; the screen is shown only if the boot is still running a moment
    after the player exists, so a mission that initialises instantly never
    shows it. A JIP client that arrives after READY shows nothing.

    WHAT IT READS. GVAR(bootLog), published per line (FUNC(bootLog)) - the
    step a line belongs to is its "[TAC//PAC BOOT n/6]" prefix, and the
    highest step seen is the one running. GVAR(bootDocs), published per
    document (FUNC(bootDoc)) - the checklist under step three. GVAR(bootStep)
    - the bar's fraction, which step three fills one document at a time.

    THE BAR MOVES EVEN WHILE ONE DOCUMENT IS AWAITED. The extension answers
    one document per round trip and a slow one can take up to PAC_SVC_TIMEOUT
    seconds; a bar that stood still for that long read as a hang (user,
    2026-09-10). So between two published fractions the bar creeps toward
    the next document's share, by time - never past what is actually done.

Parameters:
    None

Returns:
    Nothing

Author:
    YonV
---------------------------------------------------------------------------- */

if (!hasInterface) exitWith {};

// wait for the player, then a breath - a boot that is already done here is one
// the player never needed to see.
waitUntil {sleep 0.25; !isNull player};
sleep 0.75;
if (missionNamespace getVariable [QGVAR(ready), false]) exitWith {};

private _layer = QGVAR(bootScreen) call BIS_fnc_rscLayer;
_layer cutRsc [QGVAR(bootScreen), "PLAIN", 0, false];

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent"];
private _inkHex = [_ink # 0, _ink # 1, _ink # 2, 1] call BIS_fnc_colorRGBAtoHTML;
private _muteHex = [_ink # 0, _ink # 1, _ink # 2, 0.6] call BIS_fnc_colorRGBAtoHTML;
private _dimHex = [_ink # 0, _ink # 1, _ink # 2, 0.35] call BIS_fnc_colorRGBAtoHTML;
private _accentHex = [_accent # 0, _accent # 1, _accent # 2, 1] call BIS_fnc_colorRGBAtoHTML;
private _hotHex = "#e4574a";
private _barW = 0.30;
private _t0 = diag_tickTime;

private _steps = [
    "Structure from the mission's config",
    "In-game edits and imports from the profile",
    "Structure from the database",
    "Store from the profile",
    "Store from the database",
    "Save, publish, ready"
];

// the creep: what the server last said, and when this machine heard it
private _lastFrac = -1;
private _lastAt = diag_tickTime;

// Called as `[text] call _fnc_esc` - so what arrives is an ARRAY, and CBA's
// replace wants the string out of it (the .rpt filled with "Params: Type
// Array, expected String" from here, three times a second, 2026-09-10).
private _fnc_esc = {
    private _s = _this param [0, ""];
    if !(_s isEqualType "") then {_s = str _s};
    _s = [_s, "&", "&amp;"] call CBA_fnc_replace;
    _s = [_s, "<", "&lt;"] call CBA_fnc_replace;
    [_s, ">", "&gt;"] call CBA_fnc_replace
};

while {!(missionNamespace getVariable [QGVAR(ready), false])} do {
    private _disp = uiNamespace getVariable [QGVAR(bootDisp), displayNull];
    if (!isNull _disp) then {
        private _elapsed = round (diag_tickTime - _t0);
        private _clock = format ["%1:%2", floor (_elapsed / 60), [str (_elapsed mod 60), "0" + str (_elapsed mod 60)] select ((_elapsed mod 60) < 10)];
        (_disp displayCtrl PAC_IDC_BS_TITLE) ctrlSetStructuredText parseText format [
            "<t align='center' font='RobotoCondensedBold' size='1.6' color='%1'>TAC//PAC</t><br/><t align='center' size='0.85' color='%2'>I N I T I A L I S I N G   T H E   U N I T</t><br/><t align='center' size='0.85' color='%3'>%4</t>",
            _inkHex, _muteHex, _dimHex, _clock
        ];

        // ---- the log, by step --------------------------------------------
        private _log = missionNamespace getVariable [QGVAR(bootLog), []];
        private _byStep = [[], [], [], [], [], []];
        private _current = 0;
        {
            private _line = _x;
            private _b = _line find "]";
            if (_b > 0) then {
                private _tag = _line select [0, _b];                 // "[TAC//PAC BOOT 3/6"
                private _n = parseNumber (_tag select [(_tag find "BOOT ") + 5, 1]);
                if (_n >= 1 && _n <= 6) then {
                    (_byStep # (_n - 1)) pushBack (_line select [_b + 2]);
                    _current = _current max _n;
                };
            };
        } forEach _log;

        // ---- the bar, creeping between what the server says ----------------
        private _docs = missionNamespace getVariable [QGVAR(bootDocs), []];
        private _frac = (missionNamespace getVariable [QGVAR(bootStep), 0.02]) max 0.02 min 1;
        if (_frac isNotEqualTo _lastFrac) then {
            _lastFrac = _frac;
            _lastAt = diag_tickTime;
        };
        private _planned = 0;
        {_planned = _planned + ((_x param [3, 1]) max 1)} forEach _docs;
        private _share = 1 / (6 * (_planned max 8));                  // one document's worth of the bar
        private _creep = ((diag_tickTime - _lastAt) / PAC_SVC_TIMEOUT) min 0.9;
        private _shown = (_frac + _share * _creep) min 1;
        private _bar = _disp displayCtrl PAC_IDC_BS_BAR;
        (ctrlPosition _bar) params ["_bx", "_by", "", "_bh"];
        _bar ctrlSetPosition [_bx, _by, _shown * _barW * safeZoneW, _bh];
        _bar ctrlCommit 0.3;

        // ---- the checklist -----------------------------------------------
        // A SMALL COLOURED BOX A LINE, not a glyph: red to come, yellow in
        // progress, green done (user, 2026-09-10: "no [X] maybe small colored
        // boxes red not completed yello in progress and green complete").
        // The box is a procedural texture, so it needs no image file.
        private _fnc_box = {
            params ["_state", ["_size", "0.62"]];
            private _rgb = switch (_state) do {
                case "done";
                case "ok";
                case "empty": {"0.45,0.78,0.30"};
                case "run": {"0.93,0.75,0.20"};
                case "error": {"0.90,0.25,0.20"};
                case "skip": {"0.35,0.38,0.40"};
                default {"0.75,0.22,0.18"};
            };
            format ["<img size='%1' image='#(argb,8,8,3)color(%2,1)'/>", _size, _rgb]
        };
        private _rows = [];
        {
            private _n = _forEachIndex + 1;
            private _state = switch (true) do {
                case (_n < _current): {"done"};
                case (_n isEqualTo _current): {"run"};
                default {"wait"};
            };
            private _colour = switch (_state) do {case "done": {_muteHex}; case "run": {_inkHex}; default {_dimHex}};
            _rows pushBack format [
                "<t size='0.85'>%1  <t color='%2'>%3  %4</t></t>",
                [_state] call _fnc_box, _colour, _n, [_x] call _fnc_esc
            ];

            // EVERY LINE the running step has logged, the last line of a step
            // that is done - so what the server is doing is read as it does it,
            // not summarised (user, 2026-09-10: "i want more verbose MORE").
            private _lines = _byStep # _forEachIndex;
            private _keep = [1, 2] select (_state isEqualTo "run");
            if (count _lines > _keep) then {_lines = _lines select [(count _lines) - _keep, _keep]};
            if (_state isNotEqualTo "wait") then {
                {
                    private _said = _x;
                    if (count _said > 150) then {_said = (_said select [0, 147]) + "..."};
                    _rows pushBack format ["<t size='0.7' color='%1'>          %2</t>", [_muteHex, _dimHex] select (_state isEqualTo "done"), [_said] call _fnc_esc];
                } forEach _lines;
            };

        } forEach _steps;

        (_disp displayCtrl PAC_IDC_BS_STEP) ctrlSetStructuredText parseText (_rows joinString "<br/>");

        // ---- the documents: three rows of ten cells ------------------------
        for "_i" from 0 to 29 do {
            private _cell = _disp displayCtrl (PAC_IDC_BS_DOC0 + _i);
            if (_i >= count _docs) then {
                _cell ctrlSetStructuredText parseText (["", format ["<t size='0.7' color='%1'>+%2 more</t>", _dimHex, (count _docs) - 30]] select (_i isEqualTo 29 && count _docs > 30));
                continue;
            };
            (_docs # _i) params [["_label", ""], ["_st", "wait"], ["_dn", 0], ["_tt", 1]];
            private _text = _label;
            if (_tt > 1) then {_text = format ["%1 %2/%3", _label, [_dn, _tt] select (_st in ["ok", "empty"]), _tt]};
            private _c = switch (_st) do {
                case "ok": {_accentHex};
                case "run": {_inkHex};
                case "error": {_hotHex};
                case "empty": {_muteHex};
                default {_dimHex};
            };
            _cell ctrlSetStructuredText parseText format ["<t size='0.7'>%1<t color='%2'> %3</t></t>", [_st, "0.55"] call _fnc_box, _c, [_text] call _fnc_esc];
        };
        private _docLine = "";
        if (_docs isNotEqualTo []) then {
            private _landed = 0;
            private _planned2 = 0;
            {
                _x params ["", "_s2", "_d2", "_t2"];
                _landed = _landed + ([_d2, _t2] select (_s2 in ["ok", "empty", "error", "skip"]));
                _planned2 = _planned2 + _t2;
            } forEach _docs;
            _docLine = format ["<t size='0.7' color='%1'>%2 of %3 documents landed</t>", _muteHex, _landed, _planned2];
            private _running = _docs select {(_x # 1) isEqualTo "run"};
            if (_running isNotEqualTo []) then {
                (_running # 0) params ["_rl", "", ["_rd", 0], ["_rt", 1], ["_rk", ""]];
                _docLine = _docLine + format ["<t size='0.7' color='%1'>   -   reading %2%3</t>", _inkHex,
                    [[_rk] call _fnc_esc, _rl] select (_rk isEqualTo ""),
                    ["", format ["  (%1 of %2)", _rd + 1, _rt]] select (_rt > 1)];
            };
        };
        (_disp displayCtrl PAC_IDC_BS_DOCLINE) ctrlSetStructuredText parseText _docLine;
    };

    // A boot that never comes up must not trap the player forever - but a
    // database read is a document at a time and fifty of them is real time,
    // so the leash is the planned documents' worth, not one timeout.
    private _planned = 0;
    {_planned = _planned + ((_x param [3, 1]) max 1)} forEach (missionNamespace getVariable [QGVAR(bootDocs), []]);
    if (diag_tickTime - _t0 > (PAC_SVC_TIMEOUT * ((_planned max 4) + 2))) exitWith {};
    sleep 0.3;
};

// Ready: fill the bar, say so for a beat, then fade.
private _disp = uiNamespace getVariable [QGVAR(bootDisp), displayNull];
if (!isNull _disp) then {
    private _bar = _disp displayCtrl PAC_IDC_BS_BAR;
    (ctrlPosition _bar) params ["_bx", "_by", "", "_bh"];
    _bar ctrlSetPosition [_bx, _by, _barW * safeZoneW, _bh];
    _bar ctrlCommit 0.2;
    private _elapsed = round (diag_tickTime - _t0);
    (_disp displayCtrl PAC_IDC_BS_STEP) ctrlSetStructuredText parseText format [
        "<t align='center' font='RobotoCondensedBold' size='0.85' color='%1'>READY</t>", _accentHex
    ];
    (_disp displayCtrl PAC_IDC_BS_TITLE) ctrlSetStructuredText parseText format [
        "<t align='center' font='RobotoCondensedBold' size='1.6' color='%1'>TAC//PAC</t><br/><t align='center' size='0.85' color='%2'>I N I T I A L I S I N G   T H E   U N I T</t><br/><t align='center' size='0.85' color='%3'>%4:%5</t>",
        _inkHex, _muteHex, _dimHex, floor (_elapsed / 60), [str (_elapsed mod 60), "0" + str (_elapsed mod 60)] select ((_elapsed mod 60) < 10)
    ];
    for "_i" from 0 to 29 do {(_disp displayCtrl (PAC_IDC_BS_DOC0 + _i)) ctrlSetStructuredText parseText ""};
    (_disp displayCtrl PAC_IDC_BS_DOCLINE) ctrlSetStructuredText parseText "";
};
sleep 1.2;
_layer cutFadeOut 0.6;
