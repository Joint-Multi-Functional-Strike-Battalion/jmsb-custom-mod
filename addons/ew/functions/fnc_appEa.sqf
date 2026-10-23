#include "script_component.hpp"
/*
 * Author: JMSB
 * The EW app's EA tab (DESIGN_EW "EA") as a jammer CONTROL PANEL (user,
 * 2026-10-21: "I was hoping for an RF page like this" - a ground-jammer
 * panel). Two columns:
 *
 *   LEFT   the jammer's DEVICE ID and state (TRANSMITTING / STANDBY / AUTO
 *          STANDBY / THERMAL CUTOUT / BATTERY FLAT) and what it is doing,
 *          then one row per setting - JAM MODE, TARGET (stepped with the
 *          arrows: a band for barrage, an ES track for spot), FREQ FILTER and
 *          the TUNED frequency (barrage), PATTERN and its AZIMUTH, TX POWER,
 *          DUTY, OPERATION (continuous / auto, and what auto is doing) - the
 *          transmitter switch, DECOYS, and the side's other jammers by ID.
 *   RIGHT  the spectrum where he stands as a bar per band (his own jammer's
 *          band red, a band an emitter is heard on in the accent, clear in
 *          green) with a tick per heard emitter at its MHz, the DETECTED list
 *          (the side's ES tracks with their MHz), the TRANSMITTER and POWER
 *          SYSTEM blocks with the BATTERY and HEAT bars, what is being done to
 *          him here, and the footer.
 *
 * NOTHING ON IT IS DECORATION. Every value is his slice (FUNC(publish)) or
 * the scanner's reading, and every press is a change sent to the server
 * (FUNC(jamSet)), which checks his kit and answers in his next slice. Spot,
 * spoof and targeted are ISR's, and drawn dim for anyone else.
 *
 * Also drawn by the JAMMING app (jmfsb_tacpad_apps), on its own frame.
 *
 * Arguments:
 * 0: App body <CONTROL>
 * 1: Top y <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, 0.05] call jmfsb_ew_fnc_appEa
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_top", 0, [0]]];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);
private _accentText = ["accentText"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _green = ["swatchGreen"] call EFUNC(tacpad,theme);
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

GVAR(mine) params ["", "_tracks", "", "_spectrum", "_kit", "_jam", "", "", "_decoys", ["_sideJams", []]];
_kit params ["", "_hasJammer", "", "_isr"];
_jam params [
    ["_mode", MODE_BARRAGE], ["_band", ""], ["_track", ""], ["_net", ""], ["_power", 0],
    ["_duty", count DUTY_STEPS - 1], ["_on", false], ["_dBm", 0], ["_radius", 0],
    ["_devId", ""], ["_tx", false], ["_operation", []], ["_pattern", []], ["_filter", []], ["_powerSys", []]
];
_operation params [["_op", OP_CONTINUOUS], ["_engaged", false], ["_engagedWhy", ""]];
_pattern params [["_pat", PATTERN_OMNI], ["_azimuth", 0]];
_filter params [["_filt", FILTER_BROADBAND], ["_freq", 0]];
_powerSys params [["_wh", 0], ["_whFull", 1], ["_heat", 0], ["_cutout", false], ["_gen", false], ["_fuel", 0], ["_wIn", 0], ["_wDraw", 0]];
private _bands = VEHICLE_BANDS;
private _powers = POWER_VEHICLE;
private _onAir = _hasJammer && _tx;
private _flat = !_gen && _wh <= 0;
private _targeted = _mode isEqualTo MODE_BARRAGE && _filt isEqualTo FILTER_TARGETED;

private _fnc_mhz = {
    params ["_mhz"];
    if (_mhz >= MHZ_COARSE_ABOVE) then {str round _mhz} else {_mhz toFixed MHZ_DECIMALS}
};
private _azText = format ["%1%2", [_azimuth, AZIMUTH_DIGITS] call CBA_fnc_formatNumber, DEGREE_SIGN];

// The bands his jammer is sitting on right now: the barrage band, every band
// on a sweep, the spot target's band. GPS and spoof sit on no comms band.
private _jammedBands = if (!_onAir) then {[]} else {
    switch (_mode) do {
        case MODE_BARRAGE: {[_band]};
        case MODE_SWEEP: {_bands};
        case MODE_SPOT: {
            private _t = _tracks param [_tracks findIf {(_x select 0) isEqualTo _track}, []];
            [_t param [1, ""]] - [""]
        };
        default {[]};
    }
};
private _heardBands = _tracks apply {_x select 1};

// What it is aimed at, in words, for the line under the state and the footer.
private _what = switch (_mode) do {
    case MODE_BARRAGE: {
        switch (true) do {
            case (!_targeted): {format ["%1 BROADBAND", _band]};
            case (_freq <= 0): {format ["%1 - TUNE A FREQUENCY", _band]};
            default {format ["%1 %2 MHZ", _band, [_freq] call _fnc_mhz]};
        }
    };
    case MODE_SPOT: {[format ["%1 - %2", _track, _net], "NO TARGET"] select (_track isEqualTo "")};
    case MODE_SWEEP: {_bands joinString " / "};
    default {format ["RADIUS %1 M", round _radius]};
};

private _fnc_send = {
    params ["_ctrl"];
    [player, [_ctrl getVariable [QGVAR(data), []]]] call FUNC(jamSet);
};
private _fnc_label = {
    params ["_x0", "_y0", "_cw", "_text"];
    [_body, [_x0, _y0, _cw, _rowH], _text, _muted, PANEL_LABEL_SIZE, true, "left", true] call EFUNC(tacpad,drawText);
};

private _leftW = _w * PANEL_LEFT_W;
private _rightX = _leftW + _w * PANEL_GAP_W;
private _rightW = _w - _rightX - _pad;
private _lx = _pad;
private _lw = _leftW - _pad;
private _bottom = _h - _padY;

// ============================================================== LEFT ====
private _atY = _top;

// THE STATE LINE under the device ID, and what it is doing under it.
private _stateText = switch (true) do {
    case (!_hasJammer): {"NO JAMMER"};
    case (_tx): {"TRANSMITTING"};
    case (_on && _cutout): {"THERMAL CUTOUT"};
    case (_on && _flat): {"BATTERY FLAT"};
    case (_on): {"AUTO STANDBY"};
    default {"STANDBY"};
};
private _stateColour = switch (true) do {
    case (_onAir): {COLOUR_TX_ON};
    case (_hasJammer && _on): {_accentText};
    default {_ink};
};
[_body, [_lx, _atY, _lw, _rowH * PANEL_STATE_ROWS], [_stateText, format ["%1  %2", _devId, _stateText]] select (_hasJammer && _devId isNotEqualTo ""), _stateColour, PANEL_STATE_SIZE, true] call EFUNC(tacpad,drawText);
_atY = _atY + _rowH * PANEL_STATE_ROWS;

if (!_hasJammer) then {
    [_body, [_lx, _atY, _lw, _rowH], "CREW A VEHICLE WITH AN EW JAMMER MODULE IN ITS CARGO", _muted, PANEL_NOTE_SIZE] call EFUNC(tacpad,drawText);
    _atY = _atY + _rowH * PANEL_ROW_STEP;
} else {
    [_body, [_lx, _atY, _lw, _rowH], format ["%1 - %2", toUpper _mode, _what], _accentText, PANEL_SUB_SIZE, true, "left", true] call EFUNC(tacpad,drawText);
    _atY = _atY + _rowH * PANEL_ROW_STEP;

    // One setting row: its label left, its cells right - or, stacked, the
    // label on a line of its own and the cells the full width under it. A
    // cell is [text, selected, change, enabled, weight]; a change that is a
    // STRING marks a readout, the value the arrows either side step.
    private _labelW = _lw * PANEL_INLINE_LABEL_W;
    private _fnc_row = {
        params ["_label", "_cells", ["_stacked", false]];
        private _cellH = _rowH * PANEL_CELL_ROWS;
        private _cx = _lx + _labelW;
        if (_stacked) then {
            [_lx, _atY, _lw, _label] call _fnc_label;
            _atY = _atY + _rowH;
            _cx = _lx;
        } else {
            [_body, [_lx, _atY, _labelW, _cellH], _label, _muted, PANEL_LABEL_SIZE, true, "left", true] call EFUNC(tacpad,drawText);
        };
        private _weights = 0;
        {
            _weights = _weights + (_x param [4, 1]);
        } forEach _cells;
        private _unit = (_lx + _lw - _cx) / (_weights max 1);
        {
            _x params ["_text", "_selected", "_change", ["_enabled", true], ["_weight", 1]];
            private _pos = [_cx, _atY, _unit * _weight - _pad, _cellH];
            _cx = _cx + _unit * _weight;
            if (_change isEqualType "") then {
                [_body, _pos, [_dim, _ink] select _selected, RULE_THIN] call EFUNC(tacpad,drawFrame);
                [_body, _pos, _text, [_dim, _ink] select _selected, PANEL_SUB_SIZE, true, "center", true] call EFUNC(tacpad,drawText);
                continue;
            };
            [_body, _pos, _text, _selected, _fnc_send, _change, _enabled] call FUNC(appButton);
        } forEach _cells;
        _atY = _atY + _cellH + _rowH * PANEL_ROW_AIR;
    };
    // Arrows round a readout, cycling through a list of changes.
    private _fnc_stepper = {
        params ["_choices", "_current", "_shown", ["_live", true]];
        private _n = count _choices;
        private _step = _live && _n > 0;
        private _prev = if (_step) then {_choices select ((((_current max 0) - 1) + _n) mod _n)} else {[]};
        private _next = if (_step) then {_choices select (((_current max -1) + 1) mod _n)} else {[]};
        [
            [ARROW_PREV, false, _prev, _step],
            [_shown, _live, "", true, PANEL_READOUT_WEIGHT],
            [ARROW_NEXT, false, _next, _step]
        ]
    };

    ["JAM MODE", MODES apply {[toUpper _x, _x isEqualTo _mode, ["mode", _x], _isr || {!(_x in MODES_ISR)}]}, true] call _fnc_row;

    // TARGET, stepped with the arrows through what this mode can aim at.
    private _choices = switch (_mode) do {
        case MODE_BARRAGE: {_bands apply {["band", _x]}};
        case MODE_SPOT: {_tracks apply {["track", _x select 0]}};
        default {[]};
    };
    private _current = switch (_mode) do {
        case MODE_BARRAGE: {_bands find _band};
        case MODE_SPOT: {_tracks findIf {(_x select 0) isEqualTo _track}};
        default {-1};
    };
    private _shown = switch (_mode) do {
        case MODE_BARRAGE: {_band};
        case MODE_SPOT: {[_track, "NO ES TRACK"] select (_choices isEqualTo [] || _track isEqualTo "")};
        default {_what};
    };
    ["TARGET", [_choices, _current, _shown, _choices isNotEqualTo []] call _fnc_stepper] call _fnc_row;

    // FREQ FILTER and the frequency it is tuned to: barrage only. The tuning
    // steps through the MHz of the side's tracks a vehicle jammer reaches.
    if (_mode isEqualTo MODE_BARRAGE) then {
        ["FILTER", FILTERS apply {
            [toUpper _x, _x isEqualTo _filt, ["filter", _x], _isr || _x isNotEqualTo FILTER_TARGETED]
        }] call _fnc_row;
        if (_targeted) then {
            private _heard = [];
            {
                if ((_x select 1) in _bands) then {_heard pushBack [_x param [11, 0], _x select 0, _x select 1]};
            } forEach _tracks;
            _heard sort true;
            private _mhzs = [];
            private _tunes = [];
            {
                _x params ["_m", "_id"];
                if (_m in _mhzs) then {continue};
                _mhzs pushBack _m;
                _tunes pushBack ["freq", _id];
            } forEach _heard;
            private _tuned = [format ["%1 MHZ", [_freq] call _fnc_mhz], "NOT TUNED"] select (_freq <= 0);
            ["TUNED", [_tunes, _mhzs find _freq, [_tuned, "NO ES TRACK"] select (_tunes isEqualTo []), _tunes isNotEqualTo []] call _fnc_stepper] call _fnc_row;
        };
    };

    // PATTERN, and the sector's azimuth stepped AZIMUTH_STEP_DEG a press.
    if (_mode in [MODE_BARRAGE, MODE_SPOT, MODE_SWEEP]) then {
        ["PATTERN", [
            ["OMNI", _pat isEqualTo PATTERN_OMNI, ["pattern", PATTERN_OMNI]],
            [format ["SECTOR %1", SECTOR_WIDTH_DEG], _pat isEqualTo PATTERN_SECTOR, ["pattern", PATTERN_SECTOR]]
        ]] call _fnc_row;
        if (_pat isEqualTo PATTERN_SECTOR) then {
            ["AZIMUTH", [
                [ARROW_PREV, false, ["azimuth", _azimuth - AZIMUTH_STEP_DEG]],
                [_azText, true, "", true, PANEL_READOUT_WEIGHT],
                [ARROW_NEXT, false, ["azimuth", _azimuth + AZIMUTH_STEP_DEG]]
            ]] call _fnc_row;
        };
    };

    ["TX POWER", _powers apply {
        [format ["%1 W", round ((10 ^ (_x / 10)) / MW_PER_W)], (_powers find _x) isEqualTo _power, ["power", _powers find _x]]
    }] call _fnc_row;
    ["DUTY", DUTY_STEPS apply {
        [format ["%1%2", round (_x * PERCENT), "%"], (DUTY_STEPS find _x) isEqualTo _duty, ["duty", DUTY_STEPS find _x]]
    }] call _fnc_row;

    // OPERATION, and what AUTO is doing: engaged on what, or waiting.
    private _autoText = switch (true) do {
        case (_op isNotEqualTo OP_AUTO): {"ON WHEN SWITCHED ON"};
        case (_engaged): {format ["ENGAGED - %1", _engagedWhy]};
        default {"STANDBY - NOTHING HOSTILE"};
    };
    ["OPERATION", (OPERATIONS apply {[toUpper _x, _x isEqualTo _op, ["operation", _x]]}) + [[_autoText, _op isEqualTo OP_AUTO && _engaged, "", true, PANEL_READOUT_WEIGHT]]] call _fnc_row;

    // THE TRANSMITTER SWITCH, the full width: red to take it off the air,
    // green to put it on.
    private _txPos = [_lx, _atY, _lw - _pad, _rowH * PANEL_TX_ROWS];
    [_body, _txPos, [_green, COLOUR_TX_ON] select _on] call EFUNC(tacpad,drawFill);
    [_body, _txPos, ["SWITCH TRANSMITTER ON", "SWITCH TRANSMITTER OFF"] select _on, COLOUR_ON_SIGNAL, PANEL_TX_SIZE, true, "center", true] call EFUNC(tacpad,drawText);
    private _hit = [_body, _txPos, _fnc_send] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(data), ["on", !_on]];
    _atY = _atY + _rowH * (PANEL_TX_ROWS + PANEL_ROW_AIR);
};

// --- DECOYS ---------------------------------------------------------------
[_body, [_lx, _atY, _lw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
_atY = _atY + _padY;
[_lx, _atY, _lw, format ["DECOYS - %1 OF %2 OUT", _decoys, DECOYS_PER_MAN]] call _fnc_label;
_atY = _atY + _rowH;
if (_isr) then {
    private _profiles = DECOY_PROFILES;
    private _cellW = _lw / (count _profiles + 1);
    {
        [_body, [_lx + _forEachIndex * _cellW, _atY, _cellW - _pad, _rowH], toUpper _x, _x isEqualTo GVAR(decoyProfile), {
            params ["_ctrl"];
            GVAR(decoyProfile) = _ctrl getVariable [QGVAR(data), "handheld"];
            // Redraw whichever app this panel is on - TAC//EW or JAMMING.
            {[uiNamespace getVariable [QEGVAR(tacpad,appCurrent), APP_ID]] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }, _x] call FUNC(appButton);
    } forEach _profiles;
    [_body, [_lx + count _profiles * _cellW, _atY, _cellW - _pad, _rowH], "PLACE DECOY", false, {
        [player, GVAR(decoyProfile), ""] call FUNC(decoyPlace);
    }, "", _decoys < DECOYS_PER_MAN] call FUNC(appButton);
} else {
    [_body, [_lx, _atY, _lw, _rowH], "DECOYS ARE FOR ISR OPERATORS", _dim, PANEL_NOTE_SIZE] call EFUNC(tacpad,drawText);
};
_atY = _atY + _rowH * PANEL_ROW_STEP;

// --- NETWORK: the side's other jammers by ID, at the foot of the column ----
private _onCount = {_x param [2, false]} count _sideJams;
private _others = _sideJams select {(_x param [3, ""]) isNotEqualTo _devId || !_hasJammer};
private _network = if (_sideJams isEqualTo []) then {"NETWORK - NO JAMMER ON THE SIDE"} else {
    format ["NETWORK - %1 ON THE SIDE, %2 ON AIR%3", count _sideJams, _onCount,
        [": " + (((_others select [0, NETWORK_SHOWN]) apply {
            _x params [["_at", [0, 0]], ["_m", ""], ["_o", false], ["_id", ""]];
            format ["%1 %2 %3", _id, toUpper _m, ["STBY", "ON"] select _o]
        }) joinString " / "), ""] select (_others isEqualTo [])]
};
[_body, [_lx, (_atY max (_bottom - _rowH * PANEL_FOOT_ROWS)), _lw, _rowH * PANEL_FOOT_ROWS], _network, _muted, PANEL_NOTE_SIZE, true] call EFUNC(tacpad,drawText);

// ============================================================= RIGHT ====
_atY = _top;
[_rightX, _atY, _rightW, "SPECTRUM HERE - NOISE ABOVE FLOOR"] call _fnc_label;
_atY = _atY + _rowH;

// THE GRAPH: a bar per band, its height the rise above the floor, a tick at
// the MHz of each emitter heard on it (his tuned frequency in red), the band
// and its MHz under it; the legend to its right.
private _graphW = _rightW * (1 - PANEL_LEGEND_W);
private _graphH = _rowH * PANEL_GRAPH_ROWS;
private _barsH = _graphH - _rowH * 3;
[_body, [_rightX, _atY, _graphW, _graphH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
private _slotW = _graphW / ((count _spectrum) max 1);
// Where a frequency sits along a band's ranges, 0 to 1.
private _fnc_frac = {
    params ["_ranges", "_mhz"];
    private _span = 0;
    private _below = 0;
    {
        _x params ["_lo", "_hi"];
        _span = _span + _hi - _lo;
        if (_mhz > _hi) then {_below = _below + _hi - _lo} else {_below = _below + ((_mhz - _lo) max 0)};
    } forEach _ranges;
    _below / (_span max 1)
};
{
    _x params ["_b", "_noise", "_floor"];
    private _rise = (_noise - _floor) max 0;
    private _colour = switch (true) do {
        case (_b in _jammedBands): {COLOUR_TX_ON};
        case (_b in _heardBands): {_accent};
        default {_green};
    };
    private _bh = (_barsH * ((_rise / SPECTRUM_SPAN_DB) min 1)) max (PANEL_BAR_MIN_PX * pixelH);
    private _bx = _rightX + _forEachIndex * _slotW + _slotW * PANEL_BAR_INSET;
    private _bw = _slotW * (1 - 2 * PANEL_BAR_INSET);
    private _baseY = _atY + _rowH + _barsH;
    [_body, [_bx, _baseY - _bh, _bw, _bh], _colour] call EFUNC(tacpad,drawFill);

    private _ranges = [_b] call EFUNC(rf,bandMhz);
    private _tickH = _rowH * PANEL_TICK_ROWS;
    {
        if ((_x select 1) isNotEqualTo _b) then {continue};
        private _tx0 = _bx + _bw * ([_ranges, _x param [11, 0]] call _fnc_frac);
        [_body, [_tx0, _baseY - _tickH, PANEL_TICK_PX * pixelW, _tickH], _ink] call EFUNC(tacpad,drawFill);
    } forEach _tracks;
    if (_onAir && _targeted && _b isEqualTo _band && _freq > 0) then {
        private _tx0 = _bx + _bw * ([_ranges, _freq] call _fnc_frac);
        [_body, [_tx0, _atY + _rowH, PANEL_TICK_PX * pixelW, _barsH], COLOUR_TX_ON] call EFUNC(tacpad,drawFill);
    };

    private _span = if (_ranges isEqualTo []) then {""} else {
        format ["%1-%2", (_ranges select 0) select 0, (_ranges select -1) select 1]
    };
    [_body, [_rightX + _forEachIndex * _slotW, _atY, _slotW, _rowH], format ["+%1 DB", round _rise], [_muted, _ink] select (_rise > 0), PANEL_NOTE_SIZE, _rise > 0, "center"] call EFUNC(tacpad,drawText);
    [_body, [_rightX + _forEachIndex * _slotW, _baseY, _slotW, _rowH], _b, _ink, PANEL_SUB_SIZE, true, "center", true] call EFUNC(tacpad,drawText);
    [_body, [_rightX + _forEachIndex * _slotW, _baseY + _rowH, _slotW, _rowH], _span, _muted, PANEL_NOTE_SIZE, false, "center"] call EFUNC(tacpad,drawText);
} forEach _spectrum;

private _legendX = _rightX + _graphW + _pad;
private _legendW = _rightW - _graphW - _pad;
{
    _x params ["_colour", "_text"];
    private _ly = _atY + _rowH * (_forEachIndex + 1);
    [_body, [_legendX, _ly + _rowH * PANEL_SWATCH_INSET, _rowH * PANEL_SWATCH, _rowH * PANEL_SWATCH], _colour] call EFUNC(tacpad,drawFill);
    [_body, [_legendX + _rowH, _ly, _legendW - _rowH, _rowH], _text, _ink, PANEL_NOTE_SIZE, true, "left", true] call EFUNC(tacpad,drawText);
} forEach [[COLOUR_TX_ON, "YOUR JAMMER"], [_accent, "EMITTER HEARD"], [_green, "CLEAR"], [_ink, "EMITTER MHZ"]];
_atY = _atY + _graphH + _padY * 2;

// --- DETECTED: the side's ES tracks, strongest first -----------------------
[_rightX, _atY, _rightW, format ["DETECTED - %1 TRACK%2", count _tracks, ["S", ""] select (count _tracks == 1)]] call _fnc_label;
_atY = _atY + _rowH;
[_body, [_rightX, _atY, _rightW, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
if (_tracks isEqualTo []) then {
    [_body, [_rightX, _atY, _rightW, _rowH], "NOTHING HEARD - NO EMITTER IN REACH OF YOUR SIDE'S SETS", _dim, PANEL_NOTE_SIZE] call EFUNC(tacpad,drawText);
    _atY = _atY + _rowH;
} else {
    // [dBm, index] pairs: sorting the tracks themselves would compare their
    // mixed-type fields on a tie.
    private _keys = [];
    {_keys pushBack [_x select 2, _forEachIndex]} forEach _tracks;
    _keys sort false;
    private _sorted = _keys apply {_tracks select (_x select 1)};
    {
        _x params ["_id", "_b", "_dbm", "", "", "_fix", "", "", "", "_cuts", "", ["_mhz", 0]];
        private _target = _onAir && {(_mode isEqualTo MODE_SPOT && _id isEqualTo _track) || {_targeted && _mhz isEqualTo _freq}};
        private _textColour = [_ink, COLOUR_TX_ON] select _target;
        private _barX = _rightX + _rightW * DETECTED_BAR_AT;
        private _barW = _rightW * DETECTED_BAR_W;
        private _fill = (((_dbm - DBM_BAR_MIN) / (DBM_BAR_MAX - DBM_BAR_MIN)) max 0) min 1;
        [_body, [_rightX, _atY, _rightW * DETECTED_BAR_AT, _rowH], format ["%1  %2 %3  %4", _id, _b, [_mhz] call _fnc_mhz, [_x, _isr] call FUNC(classShown)], _textColour, PANEL_ROW_SIZE, true] call EFUNC(tacpad,drawText);
        [_body, [_barX, _atY + _rowH * PANEL_BAR_TRACK, _barW, _rowH * (1 - 2 * PANEL_BAR_TRACK)], _line] call EFUNC(tacpad,drawFill);
        [_body, [_barX, _atY + _rowH * PANEL_BAR_TRACK, _barW * _fill, _rowH * (1 - 2 * PANEL_BAR_TRACK)], [_green, COLOUR_TX_ON] select (_b in _jammedBands)] call EFUNC(tacpad,drawFill);
        [_body, [_barX + _barW, _atY, _rightW - (_barX - _rightX) - _barW, _rowH], format ["%1 DBM", _dbm], _ink, PANEL_ROW_SIZE, false, "right"] call EFUNC(tacpad,drawText);

        // A press aims a spot jammer at it, tunes a targeted one to it;
        // otherwise it is shown on the map.
        private _at = if (_fix isNotEqualTo []) then {_fix} else {(_cuts param [count _cuts - 1, [[0, 0]]]) select 0};
        private _change = switch (true) do {
            case (!_hasJammer): {[]};
            case (_mode isEqualTo MODE_SPOT): {["track", _id]};
            case (_targeted && {_b in _bands}): {["freq", _id]};
            default {[]};
        };
        private _hit = [_body, [_rightX, _atY, _rightW, _rowH], {
            params ["_ctrl"];
            (_ctrl getVariable [QGVAR(data), []]) params ["_change", "_at"];
            if (_change isNotEqualTo []) then {
                [player, [_change]] call FUNC(jamSet);
            } else {
                [_at] call FUNC(showOnMap);
            };
        }] call EFUNC(tacpad,drawHit);
        _hit setVariable [QGVAR(data), [_change, _at]];
        _atY = _atY + _rowH;
        if (_forEachIndex >= DETECTED_MAX - 1) exitWith {};
    } forEach _sorted;
};
_atY = _atY + _padY * 2;

// --- TRANSMITTER | POWER SYSTEM, side by side, then BATTERY and HEAT -------
if (_hasJammer) then {
    private _halfW = (_rightW - _pad) / 2;
    private _px = _rightX + _halfW + _pad;
    [_rightX, _atY, _halfW, "TRANSMITTER"] call _fnc_label;
    [_px, _atY, _halfW, "POWER SYSTEM"] call _fnc_label;
    _atY = _atY + _rowH;

    private _watts = (10 ^ (_dBm / 10)) / MW_PER_W;
    private _dutyFrac = DUTY_STEPS param [_duty, 1];
    private _state = switch (true) do {
        case (_tx): {"ON AIR"};
        case (!_on): {"OFF AIR"};
        case (_cutout): {"CUT OUT"};
        case (_flat): {"BATTERY FLAT"};
        default {"AUTO STANDBY"};
    };
    private _netW = _wIn - _wDraw;
    private _net = switch (true) do {
        case (_netW > 0): {format ["+%1 W CHARGING", _netW]};
        case (_netW < 0): {format ["%1 W DRAINING", _netW]};
        case (_wh >= _whFull): {"0 W - FULL"};
        default {"0 W - IDLE"};
    };
    private _cooling = switch (true) do {
        case (_cutout): {["CUTOUT", COLOUR_TX_ON]};
        case (_heat >= HEAT_HOT): {["HOT", _accentText]};
        default {["NORMAL", _ink]};
    };
    private _fnc_kv = {
        params ["_x0", "_y0", "_k", "_v", ["_colour", _ink]];
        [_body, [_x0, _y0, _halfW * PANEL_KEY_W, _rowH], _k, _muted, PANEL_NOTE_SIZE, true, "left", true] call EFUNC(tacpad,drawText);
        [_body, [_x0 + _halfW * PANEL_KEY_W, _y0, _halfW * (1 - PANEL_KEY_W), _rowH], _v, _colour, PANEL_ROW_SIZE, true] call EFUNC(tacpad,drawText);
    };
    private _left = [
        ["VEHICLE", toUpper getText (configOf objectParent player >> "displayName")],
        ["OUTPUT", format ["%1 W - %2 DBM", round _watts, _dBm]],
        ["DUTY", format ["%1%2 - MEAN %3 W", round (_dutyFrac * PERCENT), "%", round (_watts * _dutyFrac)]],
        ["STATE", _state, [_ink, COLOUR_TX_ON] select _tx],
        ["PATTERN", ["OMNI", format ["SECTOR %1 +%2 DB", _azText, SECTOR_GAIN_DB]] select (_pat isEqualTo PATTERN_SECTOR)]
    ];
    private _right = [
        ["SOURCE", ["BATTERY", "GENERATOR"] select _gen],
        ["GEN FUEL", format ["%1%2", _fuel, "%"]],
        ["IN / OUT", format ["%1 W / %2 W", _wIn, _wDraw]],
        ["NET", _net, [_ink, _accentText] select (_netW < 0)],
        ["COOLING", _cooling select 0, _cooling select 1]
    ];
    {
        (_x + [_ink]) params ["_k", "_v", "_c"];
        [_rightX, _atY + _forEachIndex * _rowH, _k, _v, _c] call _fnc_kv;
    } forEach _left;
    {
        (_x + [_ink]) params ["_k", "_v", "_c"];
        [_px, _atY + _forEachIndex * _rowH, _k, _v, _c] call _fnc_kv;
    } forEach _right;
    _atY = _atY + _rowH * ((count _left) max (count _right));

    // A bar the width of the column: its key, the track, the fill, the value.
    private _fnc_bar = {
        params ["_k", "_frac", "_colour", "_v"];
        private _barX = _rightX + _rightW * PANEL_POWER_BAR_AT;
        private _barW = _rightW * PANEL_POWER_BAR_W;
        private _barY = _atY + _rowH * PANEL_BAR_TRACK;
        private _barH = _rowH * (1 - 2 * PANEL_BAR_TRACK);
        [_body, [_rightX, _atY, _barX - _rightX, _rowH], _k, _muted, PANEL_NOTE_SIZE, true, "left", true] call EFUNC(tacpad,drawText);
        [_body, [_barX, _barY, _barW, _barH], _line] call EFUNC(tacpad,drawFill);
        [_body, [_barX, _barY, _barW * ((_frac max 0) min 1), _barH], _colour] call EFUNC(tacpad,drawFill);
        [_body, [_barX + _barW, _atY, _rightX + _rightW - _barX - _barW, _rowH], _v, _ink, PANEL_ROW_SIZE, true, "right"] call EFUNC(tacpad,drawText);
        _atY = _atY + _rowH;
    };
    private _charge = _wh / (_whFull max 1);
    ["BATTERY", _charge, [[_green, _accentText] select (_charge < BATTERY_LOW_FRAC), COLOUR_TX_ON] select _flat, format ["%1 / %2 WH", _wh, _whFull]] call _fnc_bar;
    private _heatColour = switch (true) do {
        case (_cutout): {COLOUR_TX_ON};
        case (_heat >= HEAT_HOT): {_accent};
        default {_green};
    };
    ["HEAT", _heat / HEAT_CUTOUT, _heatColour, format ["%1%2", _heat, "%"]] call _fnc_bar;
    _atY = _atY + _padY * 2;
};

// --- HERE: what is being done to HIM, from the scanner ---------------------
if (!isNil QEFUNC(hacking,scannerRead) && {[player] call EFUNC(hacking,hasScanner)}) then {
    ([] call EFUNC(hacking,scannerRead)) params ["", "", "", ["_all", 0], "", "", "", "", ["_jr", 0], ["_jd", 0], ["_jg", 0]];
    if (_jr + _jd + _jg <= 0 && _all > 0) then {_jr = _all};
    [_rightX, _atY, _rightW, "JAMMED HERE"] call _fnc_label;
    _atY = _atY + _rowH;
    private _cellW = _rightW / 3;
    {
        _x params ["_name", "_f"];
        private _p = round (_f * PERCENT);
        [_body, [_rightX + _forEachIndex * _cellW, _atY, _cellW, _rowH], format ["%1 %2%3", _name, _p, "%"], [_ink, COLOUR_TX_ON] select (_p > 0), PANEL_ROW_SIZE, true] call EFUNC(tacpad,drawText);
    } forEach [["RADIO", _jr], ["DATA", _jd], ["GPS", _jg]];
    _atY = _atY + _rowH;
};

// --- RECENT ALERTS: what has been fired, flown or shelled at players lately,
// from the one bus every jmfsb system posts to - while there is room.
private _alerts = (missionNamespace getVariable [QEGVAR(common,alerts), []]) select {(_x param [4, 0]) > CBA_missionTime};
if (_alerts isNotEqualTo [] && {_atY + _rowH * 2 < _bottom - _rowH}) then {
    [_rightX, _atY, _rightW, "RECENT ALERTS"] call _fnc_label;
    _atY = _atY + _rowH;
    {
        if (_atY + _rowH > _bottom - _rowH) exitWith {};
        _x params ["_src", "_txt", "_grid", ["_sev", 0]];
        [_body, [_rightX, _atY, _rightW, _rowH], format ["%1  %2%3", toUpper _src, _txt, [format [" - %1", _grid], ""] select (_grid isEqualTo "")], [_ink, _accentText, COLOUR_TX_ON] select (_sev min 2), PANEL_ROW_SIZE] call EFUNC(tacpad,drawText);
        _atY = _atY + _rowH;
        if (_forEachIndex >= ALERTS_SHOWN - 1) exitWith {};
    } forEach _alerts;
};

// --- FOOTER ----------------------------------------------------------------
private _footer = switch (true) do {
    case (!_hasJammer): {"NO JAMMER IN YOUR KIT"};
    case (_mode in [MODE_GPS, MODE_SPOOF]): {format ["%1 - COVERAGE %2 M - %3 - %4 DBM", _devId, round _radius, toUpper _mode, _dBm]};
    default {format ["%1 - %2 - %3 - %4 DBM - %5%6 DUTY", _devId, toUpper _mode, _what, _dBm, round ((DUTY_STEPS param [_duty, 1]) * PERCENT), "%"]};
};
[_body, [_rightX, (_atY max (_bottom - _rowH)), _rightW, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
[_body, [_rightX, (_atY max (_bottom - _rowH)), _rightW, _rowH], _footer, _muted, PANEL_NOTE_SIZE, true, "right", true] call EFUNC(tacpad,drawText);
