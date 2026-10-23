#include "script_component.hpp"
/*
 * Author: JMSB
 * Builds one panel on the map display: outline, ground, header, title, meta,
 * body - then hands the body to the panel's own builder and never looks inside
 * it.
 *
 * PANELS DO NOT MOVE, and there is nothing here to move them with. Every
 * panel is where FUNC(place) puts it: its default, clamped into the safe
 * zone and pushed clear of the reserved regions. Panel geometry is set in
 * the DEFAULT_* defines in shared.inc.hpp and nowhere else, so changing one
 * changes it for everybody rather than for whoever last touched a mouse.
 *
 * The frame is an outline of four 2px edges around the ground, not a filled
 * rectangle with a smaller one on top. Same picture when the panel is opaque,
 * but it is the only version that still reads as an outline at less than full
 * opacity - and panel opacity is a setting.
 *
 * ONE HEADER TREATMENT: ink on the panel's own ground, over a 2px rule. The
 * reader used to take an inverted bar - ink fill, ground text - because that is
 * how the design draws it on the light scheme. On the night ground that inverts
 * with everything else and the reader wore a solid white cap while the panels
 * either side of it were dark, which reads as a panel that missed the scheme
 * change rather than as emphasis.
 *
 * Only the header takes mouse input. A click in the body has to reach whatever
 * the panel put there, and a frame that swallowed clicks would make every list
 * in the suite unusable.
 *
 * Arguments:
 * 0: Map display <DISPLAY>
 * 1: Panel record <HASHMAP>
 *
 * Return Value:
 * The body control the panel should fill <CONTROL>
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_panel", createHashMap, [createHashMap]]];

if (isNull _display) exitWith {controlNull};

private _id = _panel get "id";
private _slot = _panel get "slot";

([_id, _panel get "default"] call FUNC(place)) params ["_pos", "_fr"];
_pos params ["_x", "_y", "_w", "_h"];

([] call FUNC(theme)) params ["_ground", "_ink", "_accent", "_line"];

private _bx = RULE_THICK * pixelW;
private _by = RULE_THICK * pixelH;
private _pad = PAD * HOST_W;
private _headerH = HEADER_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;

private _group = _display ctrlCreate [QGVAR(panel), IDC_PANEL(_slot)];
// TAGGED AS OURS. FORCE CLOSE sweeps the display for this mark, so a group
// the suite loses its reference to - a panel built twice, a rebuild that
// raced an open - can still be found and removed. An orphan is exactly the
// window that "will not close": nothing tracks it, so nothing deletes it.
_group setVariable [QGVAR(owned), true];
_group ctrlSetPosition _pos;
_group ctrlCommit 0;

// A panel rebuilt WHILE AN APP IS OPEN stays hidden like the rest - freshly
// created means freshly stacked above the app, and its ground would eat the
// app's presses. It reappears when the app closes.
if ((uiNamespace getVariable [QGVAR(appCurrent), ""]) isNotEqualTo "") then {
    _group ctrlShow false;
};

// Ground first, outline over it, so the edges are never covered by the fill.
private _fill = _display ctrlCreate [QGVAR(fill), IDC_GROUND(_slot), _group];
_fill ctrlSetPosition [0, 0, _w, _h];
_fill ctrlSetBackgroundColor _ground;
_fill ctrlCommit 0;

_group setVariable [QGVAR(frame), [_group, [0, 0, _w, _h], _ink, RULE_THICK] call FUNC(drawFrame)];

// Dead ground still has to eat the click. A press that lands between two rows
// would otherwise fall through to the map underneath and pan it or drop a
// marker - the panel would be a window rather than a surface. Returning true
// from the handler is what stops it going any further.
_fill ctrlAddEventHandler ["MouseButtonDown", {true}];

// A CHROMELESS PANEL HAS NO TITLE BAR AT ALL - no header, no rule, no title, no
// meta. It is a button, and the three strips under the reader are registered
// that way: a header reading SETTINGS over a cell reading SETTINGS is the same
// word twice, and on a control that short the bar was half its height.
private _chrome = _panel getOrDefault ["chrome", true];
if (!_chrome) then {_headerH = 0};

private _ruleH = [0, RULE_THICK * pixelH] select _chrome;

if (_chrome) then {
    private _header = _display ctrlCreate [QGVAR(fill), IDC_HEADER(_slot), _group];
    _header ctrlSetPosition [_bx, _by, _w - 2 * _bx, _headerH];
    _header ctrlSetBackgroundColor [0, 0, 0, 0];
    _header ctrlCommit 0;

    // The rule under the header is what separates it from the content.
    private _rule = _display ctrlCreate [QGVAR(fill), IDC_RULE(_slot), _group];
    _rule ctrlSetPosition [_bx, _by + _headerH, _w - 2 * _bx, _ruleH];
    _rule ctrlSetBackgroundColor _ink;
    _rule ctrlCommit 0;

    // NOT TRACKED. The title is the one label in the suite that is long enough for
    // faked letter-spacing to matter: "TAC//MSG - READER" tracked is 33 glyphs, it
    // ran straight under the header's own readout, and the only way to fit it was a
    // size nobody could read. Bold uppercase carries it on its own.
    private _title = _display ctrlCreate [QGVAR(cell), IDC_TITLE(_slot), _group];
    _title ctrlSetPosition [_bx + _pad, _by, (_w - 2 * _bx) * 0.58, _headerH];
    _title ctrlSetFontHeight (TEXT_BASE * pixelH * pixelGrid * HOST_K * GVAR(textScale) * GVAR(uiScale));
    _title ctrlSetStructuredText parseText format [
        "<t font='RobotoCondensedBold' size='0.85' color='%1'>%2</t>",
        _ink call BIS_fnc_colorRGBAtoHTML,
        [toUpper (_panel get "title")] call FUNC(xmlSafe)
    ];
    _title ctrlCommit 0;

    // Empty until the panel fills it. Reserved at build time so a readout arriving
    // on the first refresh cannot change the header's layout - and starting where
    // the title's box ends, so the two can never print over each other.
    private _meta = _display ctrlCreate [QGVAR(cell), IDC_META(_slot), _group];
    _meta ctrlSetPosition [_bx + (_w - 2 * _bx) * 0.58, _by, (_w - 2 * _bx) * 0.42 - _pad, _headerH];
    _meta ctrlSetFontHeight (TEXT_BASE * pixelH * pixelGrid * HOST_K * GVAR(textScale) * GVAR(uiScale));
    _meta ctrlCommit 0;
};

// The body is inset by the border on three sides and by the header and its rule
// on top, so a panel's own content never has to know the frame is there.
// Scrolling body for a real panel, plain one for a chromeless strip - see
// the note on GVAR(bodyPlain).
private _body = _display ctrlCreate [([QGVAR(bodyPlain), QGVAR(body)] select _chrome), IDC_BODY(_slot), _group];
_body ctrlSetPosition [_bx, _by + _headerH + _ruleH, _w - 2 * _bx, _h - 2 * _by - _headerH - _ruleH];
_body ctrlSetBackgroundColor [0, 0, 0, 0];
_body ctrlCommit 0;

private _open = missionNamespace getVariable [QGVAR(open), createHashMap];
_open set [_id, [_group, _body, _fr]];
GVAR(open) = _open;

[_body, _id] call (_panel get "builder");

_body
