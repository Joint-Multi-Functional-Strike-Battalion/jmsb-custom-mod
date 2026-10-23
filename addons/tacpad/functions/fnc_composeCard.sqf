#include "script_component.hpp"
/*
 * Author: JMSB
 * The inserted template's card, drawn into the compose pane the way the card is
 * printed: numbered lines, two columns, a control per field of the type that
 * field actually is.
 *
 * A LINE IS A LINE. The form used to lay every field out flat, so CASEVAC line 4
 * arrived as three unlabelled boxes called GREEN, YELLOW and RED with nothing on
 * screen saying they were LZ SECURITY or that you were meant to pick one.
 *
 * A FIELD IS ITS OWN TYPE. A field that is one of a set is drawn as that set
 * with one of them pressed; only text, numbers, grids and times are typed.
 *
 * NO LOCATION IS AUTO-FILLED. A grid that fills itself in with where you are
 * standing is a grid nobody reads before sending, and a CASEVAC pick-up that is
 * quietly your own position is how a bird goes to the wrong field. A location is
 * asked for, and there are three honest ways to answer it: CUR LOC for where
 * you are, MARKER for somewhere already marked, or type it - the two cells sit
 * on the box's right edge, as the handoff draws them, and an ingress or egress
 * carries MARKER only. A field that names a marker rather than holding a
 * position - an LZ name, a DZ mark - gets the same list and takes the marker's
 * NAME from it.
 *
 * A call sign and a time still prefill, because neither is a place: they are
 * facts the game already knows about the sender, and both are typed over in the
 * box they are shown in.
 *
 * Arguments:
 * 0: [x, width, top y, available height] of the pane, in the content group's own
 *    coordinates <ARRAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_pane", [0, 0, 0, 0], [[]], 4]];

_pane params ["_dx", "_dw", "_top", "_availH"];

private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {};

private _root = (_display displayCtrl IDC_RD_ROOT) controlsGroupCtrl IDC_RD_CONTENT;
if (isNull _root) exitWith {};

private _template = [GVAR(composeTemplate)] call EFUNC(messaging,template);
private _lines = _template getOrDefault ["lines", []];

([] call FUNC(theme)) params ["_ground", "_ink", "_accent", "_line"];

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _btnH = ([TEXT_BODY] call FUNC(textH)) + 2 * _padY;
private _fontH = ([TEXT_TITLE] call FUNC(textH)) / 1.25;
private _mute = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);
private _accentText = ["accentText"] call FUNC(theme);
private _surface = ["surface"] call FUNC(theme);

private _bodyW = _dw - 2 * _pad;
private _body = _display ctrlCreate [QGVAR(body), -1, _root];
_body ctrlSetPosition [_dx + _pad, _top, _bodyW, _availH];
_body ctrlSetBackgroundColor [0, 0, 0, 0];
_body ctrlCommit 0;

if (_lines isEqualTo []) exitWith {
    [_body, [0, 0, _bodyW, _rowH], "THIS REPORT HAS NOTHING TO FILL IN - PRESS SEND", _dim, TEXT_TITLE] call FUNC(drawText);
};

private _scrollW = 14 * pixelW;
private _colW = (_bodyW - _scrollW - _pad * 2) / 2;

// What a field currently reads as. A grid picked off the map is held as a real
// position and shown as its grid; anything typed is held as it was typed; a
// call sign or a time nobody has touched shows what the game already knows.
private _fnc_shown = {
    params ["_key", ["_field", createHashMap]];

    private _grid = GVAR(composeGridText) getOrDefault [_key, ""];
    if (_grid isNotEqualTo "") exitWith {_grid};

    private _v = GVAR(composeValues) getOrDefault [_key, ""];
    if (_v isNotEqualTo "") exitWith {
        if (_v isEqualType "") then {_v} else {str _v}
    };

    switch (_field getOrDefault ["autoFill", "none"]) do {
        case "ownCallsign": {groupId (group player)};
        case "missionTime": {
            date params ["", "", "", "_hh", "_mm"];
            format ["%1%2", [_hh, 2] call CBA_fnc_formatNumber, [_mm, 2] call CBA_fnc_formatNumber]
        };
        default {
            // "pac:section.field" - a line of the current OPORD, when the pac
            // addon is loaded. METT-TC pre-fills its M, E and C from it.
            private _auto = _field getOrDefault ["autoFill", "none"];
            if ((_auto select [0, 4]) isEqualTo "pac:" && {!isNil "jmfsb_pac_fnc_opordField"}) exitWith {
                [_auto select [4]] call jmfsb_pac_fnc_opordField
            };
            ""
        };
    }
};

// One typed box.
private _fnc_edit = {
    params ["_key", "_x", "_y", "_w", "_h", ["_field", createHashMap], ["_multi", false]];

    // A REQUIRED FIELD SEND FOUND EMPTY - see FUNC(composeSend) - is framed
    // 2px in the accent until something is put in it. The handoff's SEND
    // validation: the box that stopped the send is the box that says so.
    private _missing = _key in GVAR(composeMissing) && {([_key, _field] call _fnc_shown) isEqualTo ""};
    if (_missing) then {
        [_body, [_x, _y, _w, _h], _accent, RULE_THICK] call FUNC(drawFrame);
    } else {
        [_body, [_x, _y, _w, _h], _line, RULE_THIN] call FUNC(drawFrame);
    };

    // THE FIELD META, flush right inside the box, the design's full set: REQ
    // (never an asterisk), a number's range, AUTO on a prefilled fact, MARKER
    // on a field the marker list can answer. The edit stops short of it, so
    // the label cannot eat a click meant for the box; on a textarea it sits in
    // the first line's height rather than floating mid-void. REQ alone is in
    // the accent (accent-700 at this size, the full accent while the field is
    // holding up a send); the rest is muted.
    private _tokens = [];
    if (_field getOrDefault ["required", false]) then {_tokens pushBack "REQ"};
    private _min = _field getOrDefault ["min", -1e10];
    private _max = _field getOrDefault ["max", 1e10];
    if ((_field getOrDefault ["type", "text"]) isEqualTo "number" && {_min > -1e9} && _max < 1e9) then {
        _tokens pushBack format ["%1-%2", _min, _max];
    };
    if ((_field getOrDefault ["autoFill", "none"]) isNotEqualTo "none") then {_tokens pushBack "AUTO"};
    if ((_field getOrDefault ["source", "manual"]) isEqualTo "marker") then {_tokens pushBack "MARKER"};

    private _req = "REQ" in _tokens;
    private _rest = _tokens - ["REQ"];
    private _glyph = ([CARD_META_SIZE] call FUNC(textH)) / 1.25 * CARD_GLYPH_W * pixelW / pixelH;
    private _restText = (["", "- "] select (_req && {_rest isNotEqualTo []})) + (_rest joinString " - ");
    private _restW = [0, (count _restText) * _glyph + _pad * 0.5] select (_rest isNotEqualTo []);
    private _reqW = [0, (count "REQ ") * _glyph] select _req;
    private _metaW = (_restW + _reqW) min (_w * CARD_META_MAX_W);
    private _metaR = _x + _w - _pad * 0.5;
    if (_rest isNotEqualTo []) then {
        [_body, [_metaR - _restW, _y, _restW, _h min _btnH], _restText, _mute, CARD_META_SIZE, true, "right"] call FUNC(drawText);
    };
    if (_req) then {
        [
            _body, [_metaR - _restW - _reqW, _y, _reqW, _h min _btnH],
            "REQ", ([_accentText, _accent] select _missing), CARD_META_SIZE, true, "right"
        ] call FUNC(drawText);
    };

    private _class = ["RscEdit", "RscEditMulti"] select (_multi && {isClass (configFile >> "RscEditMulti")});
    private _edit = _display ctrlCreate [_class, -1, _body];
    _edit ctrlSetPosition [_x + _pad, _y + _padY * 0.4, _w - 2 * _pad - _metaW, _h - _padY * 0.8];
    _edit ctrlSetBackgroundColor [0, 0, 0, 0];
    _edit ctrlSetTextColor _ink;
    _edit ctrlSetFontHeight _fontH;
    _edit ctrlSetTooltip (_field getOrDefault ["hint", ""]);
    _edit ctrlSetText ([_key, _field] call _fnc_shown);
    _edit setVariable [QGVAR(fieldKey), _key];

    // THE FLAG THAT SAYS "I HOLD TEXT". FUNC(composeHarvest) reads ctrlText off
    // every control carrying a fieldKey, and an empty one means the player
    // cleared the field - so it deletes the answer. Hit areas carry a fieldKey
    // too (a bool tick, a choice segment, CURRENT LOC, MAP MARKER) and ctrlText
    // on one is always "", so harvest was deleting the value of every button on
    // the card each time anything was pressed. This is the one control on a
    // field that actually holds typing.
    _edit setVariable [QGVAR(fieldEdit), true];
    _edit ctrlCommit 0;

    // Every keystroke feeds the preview - harvest, render, rewrite the one
    // control in place. No redraw, so focus never leaves the box being typed
    // in.
    _edit ctrlAddEventHandler ["KeyUp", {
        [] call FUNC(composeHarvest);

        private _pv = uiNamespace getVariable [QGVAR(previewCtrl), controlNull];
        if (isNull _pv) exitWith {false};

        ([] call FUNC(theme)) params ["", "_ink"];
        private _pvText = [([GVAR(composeTemplate), GVAR(composeValues) toArray false, false] call EFUNC(messaging,render))] call FUNC(xmlSafe);
        _pv ctrlSetStructuredText parseText format [
            "<t font='RobotoCondensed' size='0.7' color='%1'>%2</t>",
            _ink call BIS_fnc_colorRGBAtoHTML,
            _pvText regexReplace ["\r\n", "<br/>"]
        ];
        false
    }];
};

// THE ATTACHED CELLS, the handoff's: a grid's box carries CUR LOC (own
// position) and MARKER (pick a map marker) on its right edge, in the same row,
// rather than a row of buttons under it. The caller has drawn the box short by
// exactly the cells' width; this draws them, then the marker list under the
// row when MARKER is open. Two modes, because two kinds of field want the
// list: a grid field takes the marker's POSITION - so the thread still anchors
// somewhere the map can pin - and a name field takes its NAME. Both are typed
// over afterwards like anything else.
private _cellW = _colW * CARD_CELL_W;

private _fnc_markerDrop = {
    params ["_key", "_mode", ["_cur", true]];

    private _open = GVAR(composeMarker) isEqualTo _key;

    // An ingress or an egress is never where the sender is standing, so it
    // keeps MARKER and loses CUR LOC - see the grid branch below.
    private _grid = _mode isEqualTo "pos" && _cur;
    private _mx = _cx + _colW - _cellW;

    if (_grid) then {
        private _gx = _mx - _cellW;
        [_body, [_gx, _cy, _cellW, _btnH], _surface] call FUNC(drawFill);
        [_body, [_gx, _cy, _cellW, _btnH], _ink, RULE_THICK] call FUNC(drawFrame);
        [_body, [_gx, _cy, _cellW, _btnH], "CUR LOC", _ink, CARD_CELL_SIZE, true, "center"] call FUNC(drawText);

        private _hit = [_body, [_gx, _cy, _cellW, _btnH], {
            params ["_ctrl"];
            [] call FUNC(composeHarvest);

            private _k = _ctrl getVariable [QGVAR(fieldKey), ""];

            // CUR LOC IS WHERE HIS GPS SAYS (jmfsb_ew_fnc_gpsHere, when EW is
            // loaded): the false position when spoofed, and nothing - with a
            // word on the rail - when it is denied. Type the grid instead.
            private _at = if (isNil QEFUNC(ew,gpsHere)) then {getPosATL player} else {[true] call EFUNC(ew,gpsHere)};
            if (_at isEqualTo []) exitWith {};

            // The POSITION is what is stored - the thread anchors on it and PIN
            // TO MAP has something to pin. The grid is what is shown.
            GVAR(composeValues) set [_k, _at];
            GVAR(composeGridText) set [_k, mapGridPosition _at];
            GVAR(composeMarker) = "";

            {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
        }] call FUNC(drawHit);
        _hit setVariable [QGVAR(fieldKey), _key];
    };

    // Open is the pressed state, ink - the accent is not spent on it.
    [_body, [_mx, _cy, _cellW, _btnH], [_surface, _ink] select _open] call FUNC(drawFill);
    [_body, [_mx, _cy, _cellW, _btnH], _ink, RULE_THICK] call FUNC(drawFrame);
    [_body, [_mx, _cy, _cellW, _btnH], "MARKER", [_ink, _ground] select _open, CARD_CELL_SIZE, true, "center"] call FUNC(drawText);

    private _hitM = [_body, [_mx, _cy, _cellW, _btnH], {
        params ["_ctrl"];
        [] call FUNC(composeHarvest);
        private _k = _ctrl getVariable [QGVAR(fieldKey), ""];
        GVAR(composeMarker) = [_k, ""] select (GVAR(composeMarker) isEqualTo _k);
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
    _hitM setVariable [QGVAR(fieldKey), _key];

    _cy = _cy + _btnH + _padY;

    if (!_open) exitWith {};

    // The list drops under the field it belongs to, and pushes the rest of this
    // column down rather than covering it.
    private _markers = [10] call FUNC(markerGrids);

    if (_markers isEqualTo []) exitWith {
        [_body, [_cx + _pad, _cy, _colW - _pad, _rowH * 0.9], "NO MAP MARKERS", _dim, TEXT_BODY] call FUNC(drawText);
        _cy = _cy + _rowH * 0.9;
    };

    {
        _x params ["_label", "_pos"];
        private _my = _cy + _forEachIndex * _rowH * 0.9;

        [_body, [_cx + _pad, _my, _colW * 0.6 - _pad, _rowH * 0.9], _label, _ink, TEXT_BODY] call FUNC(drawText);
        [_body, [_cx + _colW * 0.6, _my, _colW * 0.4 - _pad, _rowH * 0.9], mapGridPosition _pos, _mute, TEXT_BODY, false, "right"] call FUNC(drawText);
        [_body, [_cx, _my + _rowH * 0.9 - RULE_THIN * pixelH, _colW, RULE_THIN * pixelH], _line] call FUNC(drawFill);

        private _hitP = [_body, [_cx, _my, _colW, _rowH * 0.9], {
            params ["_ctrl"];
            [] call FUNC(composeHarvest);

            private _k = _ctrl getVariable [QGVAR(fieldKey), ""];
            if (_k isEqualTo "") exitWith {};

            if (_ctrl getVariable [QGVAR(markerMode), "pos"] isEqualTo "name") then {
                GVAR(composeValues) set [_k, _ctrl getVariable [QGVAR(markerName), ""]];
                GVAR(composeGridText) deleteAt _k;
            } else {
                private _at = _ctrl getVariable [QGVAR(markerPos), []];
                if (_at isEqualTo []) exitWith {};
                GVAR(composeValues) set [_k, _at];
                GVAR(composeGridText) set [_k, mapGridPosition _at];
            };

            GVAR(composeMarker) = "";
            {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
        }] call FUNC(drawHit);
        _hitP setVariable [QGVAR(fieldKey), _key];
        _hitP setVariable [QGVAR(markerMode), _mode];
        _hitP setVariable [QGVAR(markerPos), _pos];
        _hitP setVariable [QGVAR(markerName), _label];
    } forEach _markers;

    _cy = _cy + (count _markers) * _rowH * 0.9 + _padY;
};

// The four colours the deck's bools and choices answer in. Green and amber are
// the design's fixed swatches; red and black are the theme's own accent and
// ink, which is what the design means by them.
private _swYellow = ["swatchYellow"] call FUNC(theme);
private _gyrb = createHashMapFromArray [
    ["GREEN", ["swatchGreen"] call FUNC(theme)],
    ["YELLOW", _swYellow],
    ["AMBER", _swYellow],
    ["RED", _accent],
    ["BLACK", _ink]
];

// A choice's segmented row, the design's: one row however many segments, the
// selected cell an INK fill - the accent is spent on required and priority,
// not on which smoke colour is picked - and a swatch in any segment whose
// answer IS a colour.
private _fnc_options = {
    params ["_key", "_options", "_selected", "_handler"];

    private _perRow = count _options;
    private _segW = _colW / _perRow;

    {
        _x params ["_value", "_label"];
        private _on = _selected isEqualTo _value;
        private _sx = _cx + (_forEachIndex % _perRow) * _segW;
        private _sy = _cy;

        if (_on) then {
            [_body, [_sx, _sy, _segW - _pad, _btnH], _ink] call FUNC(drawFill);
        } else {
            [_body, [_sx, _sy, _segW - _pad, _btnH], _line, RULE_THIN] call FUNC(drawFrame);
        };

        private _sw = _gyrb getOrDefault [toUpper _value, []];
        private _lx = _sx + _pad * 0.5;
        if (_sw isNotEqualTo []) then {
            private _swh = _btnH * 0.38;
            [_body, [_lx, _sy + (_btnH - _swh) * 0.5, _swh * pixelW / pixelH, _swh], _sw] call FUNC(drawFill);
            _lx = _lx + _swh * pixelW / pixelH + _pad * 0.5;
        };

        [
            _body, [_lx, _sy, _sx + _segW - _pad - _lx, _btnH], _label,
            ([_ink, _ground] select _on), TEXT_LABEL, true,
            ["center", "left"] select (_sw isNotEqualTo [])
        ] call FUNC(drawText);

        private _hit = [_body, [_sx, _sy, _segW - _pad, _btnH], _handler] call FUNC(drawHit);
        _hit setVariable [QGVAR(fieldKey), _key];
        _hit setVariable [QGVAR(choice), _value];
        _hit setVariable [QGVAR(exclusiveKeys), _options apply {_x # 0}];
    } forEach _options;

    _cy = _cy + _btnH + _padY;
};

// ------------------------------------------------- header and badge strip ---
// The tag box and title over a 2px rule, then the card's facts on the surface
// fill - FUNC(composeCardHead), the handoff's anatomy.
private _stripH = [_body, _template, _bodyW - _scrollW] call FUNC(composeCardHead);

// TEMPLATE ON THE LEFT, THE MESSAGE ON THE RIGHT - the split the design
// draws and the user asked for three times. Every line stacks down the left
// column; the right column is the preview, drawn after the loop.
private _colY = [_stripH, _stripH];
private _half = count _lines;

{
    _x params ["", "_lineTitle", "_lineLabel", "_fields", ""];

    private _col = parseNumber (_forEachIndex >= _half);
    private _cx = _col * (_colW + _pad * 2);
    private _cy = _colY # _col;

    // ------------------------------------------------------- the line head ---
    // THE KEY BOX, the design's: the verbatim key - "Line 1", "S", "Warno 3A"
    // - in an ink border with the line title beside it. It replaces a bare
    // counter, and it is the field-key contract made visible: the key on the
    // box is the key the payload files under.
    private _keyW = (_colW * (0.085 + 0.021 * count _lineTitle)) min (_colW * 0.32);
    private _keyH = ([TEXT_LABEL] call FUNC(textH)) + _padY * 0.6;
    [_body, [_cx, _cy + (_rowH - _keyH) * 0.5, _keyW, _keyH], _ink, RULE_THICK] call FUNC(drawFrame);
    [_body, [_cx, _cy + (_rowH - _keyH) * 0.5, _keyW, _keyH], _lineTitle, _ink, CARD_TAG_SIZE, true, "center"] call FUNC(drawText);
    [_body, [_cx + _keyW + _pad, _cy, _colW - _keyW - _pad, _rowH], _lineLabel, _ink, TEXT_BODY, true, "left", true] call FUNC(drawText);
    _cy = _cy + _rowH;

    // ----------------------------------------------------------- the fields ---
    // Plain typed fields run side by side under one line - "URGENT 2 PRIORITY 1
    // ROUTINE 0" is one answer - and anything that needs a row of its own takes
    // one. The run is flushed in order, so nothing is reordered on the card.
    private _run = [];

    private _fnc_flushRun = {
        if (_run isEqualTo []) exitWith {};

        private _n = count _run;
        private _cellW = _colW / _n;

        // A PREFIXED FIELD TAKES ITS LABEL BESIDE THE BOX, bold, the way the
        // design draws EKIA and ALT - a caption row over a third-of-a-column
        // cell wrapped "FRIENDLY FORCES / POSTURE" straight into the input
        // under it. Only unprefixed fields keep a caption line, small and
        // untracked so it fits the cell it names; with one field on the line
        // the line label is the caption. No asterisk anywhere - required is
        // the REQ meta inside the field, drawn by _fnc_edit.
        private _capH = 0;
        if (_n > 1 && {(_run findIf {(_x getOrDefault ["prefix", ""]) isEqualTo ""}) > -1}) then {
            _capH = ([TEXT_LABEL] call FUNC(textH)) + _padY * 0.3;
        };

        {
            private _key = _x getOrDefault ["key", ""];
            private _sx = _cx + _forEachIndex * _cellW;
            private _prefix = _x getOrDefault ["prefix", ""];

            private _capW = 0;
            if (_n > 1) then {
                if (_prefix isEqualTo "") then {
                    [_body, [_sx, _cy, _cellW - _pad, _capH], _x getOrDefault ["hint", ""], _mute, TEXT_LABEL, true] call FUNC(drawText);
                } else {
                    // SIZED TO THE WORD, not to a flat third of the cell (user,
                    // 2026-09-03). URGENT / PRIORITY / ROUTINE over three cells
                    // of a third-width column had 34% each, and PRIORITY wrapped
                    // onto a second line - so the caption for a 0-99 box was
                    // twice the height of the box beside it.
                    //
                    // A NUMBER BOX HOLDS TWO DIGITS. It does not need the two
                    // thirds it was taking, so the label may have what it needs
                    // and the box keeps the rest - never less than 30%, which is
                    // still wider than "99" plus its range meta.
                    private _fh = ([TEXT_LABEL] call FUNC(textH)) / 1.25;
                    private _need = (count _prefix) * _fh * 0.55 * pixelW / pixelH + _pad;
                    _capW = _need min ((_cellW - _pad) * 0.70);
                    [_body, [_sx, _cy + _capH, _capW - _pad * 0.5, _btnH], toUpper _prefix, _ink, TEXT_LABEL, true] call FUNC(drawText);
                };
            };

            [_key, _sx + _capW, _cy + _capH, _cellW - _pad - _capW, _btnH, _x, false] call _fnc_edit;
        } forEach _run;

        _cy = _cy + _capH + _btnH + _padY;
        _run = [];
    };

    {
        private _field = _x;
        private _key = _field getOrDefault ["key", ""];
        private _type = _field getOrDefault ["type", "text"];
        private _choices = _field getOrDefault ["choices", []];

        // ------------------------------------------------------------ choice --
        if (_type isEqualTo "choice" && {_choices isNotEqualTo []}) then {
            call _fnc_flushRun;

            // THE ROW SAYS WHAT IT CHOOSES. A line holding several choice
            // fields - SITREP's STATUS is four - drew them as four unlabelled
            // colour rows, and nobody could tell AMMO from CE without counting.
            // One field under a line needs no caption; the line label is it.
            if (count _fields > 1) then {
                private _cap = _field getOrDefault ["prefix", ""];
                if (_cap isEqualTo "") then {_cap = _field getOrDefault ["hint", ""]};
                if (_cap isNotEqualTo "") then {
                    [_body, [_cx, _cy, _colW, _rowH * 0.65], _cap, _mute, TEXT_LABEL, true, "left", true] call FUNC(drawText);
                    _cy = _cy + _rowH * 0.65;
                };
            };

            // A required choice SEND found empty is framed in the accent, as
            // an empty required box is - see _fnc_edit.
            if (_key in GVAR(composeMissing) && {(GVAR(composeValues) getOrDefault [_key, ""]) isEqualTo ""}) then {
                [_body, [_cx, _cy, _colW - _pad, _btnH], _accent, RULE_THICK] call FUNC(drawFrame);
            };

            [
                _key,
                _choices apply {[_x, _x]},
                GVAR(composeValues) getOrDefault [_key, ""],
                {
                    params ["_ctrl"];
                    [] call FUNC(composeHarvest);
                    GVAR(composeValues) set [
                        _ctrl getVariable [QGVAR(fieldKey), ""],
                        _ctrl getVariable [QGVAR(choice), ""]
                    ];
                    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
                }
            ] call _fnc_options;

            continue;
        };

        // -------------------------------------------------------------- bool --
        // THE DESIGN'S SELECTOR ROW: a square tick, a colour swatch where the
        // key IS a colour, the key in bold, the description dimmed - and an
        // exclusive set is these rows behaving as radios. They were a
        // segmented strip once, which read as one wide button rather than
        // three answers, and a lone bool was a YES/NO box that said neither
        // what YES meant nor which way was the default.
        if (_type isEqualTo "bool") then {
            call _fnc_flushRun;

            private _on = (GVAR(composeValues) getOrDefault [_key, false]) isEqualTo true;
            private _rowB = _btnH * 0.9;
            private _boxH = _btnH * 0.5;
            private _boxW = _boxH * pixelW / pixelH;

            if (_on) then {
                [_body, [_cx, _cy + (_rowB - _boxH) * 0.5, _boxW, _boxH], _ink] call FUNC(drawFill);
            } else {
                [_body, [_cx, _cy + (_rowB - _boxH) * 0.5, _boxW, _boxH], _ink, RULE_THIN] call FUNC(drawFrame);
            };

            private _label = _field getOrDefault ["prefix", ""];
            private _desc = _field getOrDefault ["hint", ""];
            if (_label isEqualTo "") then {_label = _desc; _desc = ""};

            private _tx = _cx + _boxW + _pad;
            private _sw = _gyrb getOrDefault [toUpper _label, []];
            if (_sw isNotEqualTo []) then {
                private _swh = _boxH * 0.8;
                [_body, [_tx, _cy + (_rowB - _swh) * 0.5, _swh * pixelW / pixelH, _swh], _sw] call FUNC(drawFill);
                _tx = _tx + _swh * pixelW / pixelH + _pad;
            };

            private _labW = _colW * 0.3;
            [_body, [_tx, _cy, _labW, _rowB], toUpper _label, _ink, TEXT_LABEL, true] call FUNC(drawText);
            if (_desc isNotEqualTo "") then {
                [_body, [_tx + _labW + _pad, _cy, _cx + _colW - _tx - _labW - 2 * _pad, _rowB], _desc, _dim, TEXT_LABEL, false] call FUNC(drawText);
            };

            private _hit = [_body, [_cx, _cy, _colW, _rowB], {
                params ["_ctrl"];
                [] call FUNC(composeHarvest);
                private _k = _ctrl getVariable [QGVAR(fieldKey), ""];
                private _ex = _ctrl getVariable [QGVAR(exclusiveKeys), []];
                private _was = (GVAR(composeValues) getOrDefault [_k, false]) isEqualTo true;

                // A radio stays pressed; a lone tick toggles.
                if (_ex isEqualTo []) then {
                    GVAR(composeValues) set [_k, !_was];
                } else {
                    {GVAR(composeValues) deleteAt _x} forEach _ex;
                    GVAR(composeValues) set [_k, true];
                };
                {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
            }] call FUNC(drawHit);
            _hit setVariable [QGVAR(fieldKey), _key];

            private _exTag = _field getOrDefault ["exclusive", ""];
            private _sibs = [];
            if (_exTag isNotEqualTo "") then {
                _sibs = (_fields select {(_x getOrDefault ["exclusive", ""]) isEqualTo _exTag}) apply {_x getOrDefault ["key", ""]};
            };
            _hit setVariable [QGVAR(exclusiveKeys), _sibs];

            _cy = _cy + _rowB + _padY * 0.4;
            continue;
        };

        // -------------------------------------------------------------- grid --
        if (_type isEqualTo "grid") then {
            call _fnc_flushRun;

            // CUR LOC is offered unless the field says not to (noCur) or the
            // line is an ingress or an egress by its title or label - the
            // handoff's rule, kept even for a deck that forgot the flag.
            private _named = toUpper (_lineTitle + " " + _lineLabel);
            private _cur = !(_field getOrDefault ["noCur", false])
                && {(CARD_NO_CUR_WORDS findIf {_x in _named}) < 0};

            [_key, _cx, _cy, _colW - _cellW * ([1, 2] select _cur), _btnH, _field, false] call _fnc_edit;
            [_key, "pos", _cur] call _fnc_markerDrop;
            continue;
        };

        // ---------------------------------------------------------- textarea --
        if (_type isEqualTo "textarea") then {
            call _fnc_flushRun;
            [_key, _cx, _cy, _colW, _btnH * 2.4, _field, true] call _fnc_edit;
            _cy = _cy + _btnH * 2.4 + _padY;
            continue;
        };

        // A field that names a marker rather than holding one: the same list,
        // and it puts the marker's name in the box.
        if ((_field getOrDefault ["source", "manual"]) isEqualTo "marker") then {
            call _fnc_flushRun;

            [_key, _cx, _cy, _colW - _cellW, _btnH, _field, false] call _fnc_edit;
            [_key, "name"] call _fnc_markerDrop;
            continue;
        };

        // Everything else is a box, and boxes share a row.
        _run pushBack _field;
    } forEach _fields;

    call _fnc_flushRun;

    _cy = _cy + _padY * 0.5;
    [_body, [_cx, _cy, _colW, RULE_THIN * pixelH], _line] call FUNC(drawFill);
    _colY set [_col, _cy + _padY * 1.5];
} forEach _lines;

// ------------------------------------------------------------ the preview ---
// THE MESSAGE AS IT WILL READ, rendered off the same values the form holds,
// through the same renderer every reader uses - so what the sender sees on
// the right is literally what everyone else gets.
private _px = _colW + _pad * 2;
private _pvH = ((_colY # 0) max (_colY # 1)) - _stripH;
[_body, [_px - _pad, _stripH, RULE_THICK * pixelW, _pvH max (_rowH * 4)], _ink] call FUNC(drawFill);
[_body, [_px + _pad, _stripH, _colW - _pad, _rowH], "MESSAGE PREVIEW", _mute, TEXT_BODY, true, "left", true] call FUNC(drawText);

// ONE LIVE CONTROL, updated on every keystroke - "preview should preview the
// message", in red. The edits' KeyUp harvests and rewrites this in place, so
// the right column reads back what is being typed as it is typed.
private _pv = _display ctrlCreate [QGVAR(cell), -1, _body];
_pv ctrlSetPosition [_px + _pad, _stripH + _rowH, _colW - 2 * _pad, ((_colY # 0) max (_rowH * 8)) - _stripH];
_pv ctrlSetFontHeight (TEXT_BASE * pixelH * pixelGrid * HOST_K * GVAR(textScale) * GVAR(uiScale));
_pv ctrlCommit 0;
uiNamespace setVariable [QGVAR(previewCtrl), _pv];

private _pvText = [([GVAR(composeTemplate), GVAR(composeValues) toArray false, false] call EFUNC(messaging,render))] call FUNC(xmlSafe);
_pv ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensed' size='0.7' color='%1'>%2</t>",
    _ink call BIS_fnc_colorRGBAtoHTML,
    _pvText regexReplace ["\r\n", "<br/>"]
];

// --------------------------------------------------------------- the foot ---
// SUBJ, the design's footer: the thread-subject pattern verbatim, so the
// sender knows what the row in everyone's reader will say before pressing
// SEND - which sits one rule down in the pane, where it always was.
private _subject = _template getOrDefault ["subject", ""];
if (_subject isNotEqualTo "") then {
    private _fy = (_colY # 0) max (_colY # 1);
    [_body, [0, _fy, _bodyW - _scrollW, _rowH * 0.8 + 2 * _padY], _surface] call FUNC(drawFill);
    [_body, [0, _fy, _bodyW - _scrollW, RULE_THICK * pixelH], _ink] call FUNC(drawFill);
    _fy = _fy + _padY;
    [_body, [_pad, _fy, _bodyW * 0.1, _rowH * 0.8], "SUBJ", _mute, TEXT_LABEL, true, "left", true] call FUNC(drawText);
    [
        _body, [_pad + _bodyW * 0.1, _fy, _bodyW - _scrollW - _bodyW * 0.1 - 2 * _pad, _rowH * 0.8],
        _subject, _ink, TEXT_LABEL, true
    ] call FUNC(drawText);
};
