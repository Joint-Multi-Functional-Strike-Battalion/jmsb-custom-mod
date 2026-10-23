#include "script_component.hpp"
/*
 * Author: JMSB
 * The squad rail: one row per man, a health swatch, and the number that swatch
 * is standing for. Under them, the way into the full roster, and the legend that
 * says what the four colours mean.
 *
 * Hue is the data here and nowhere else in the suite - green up, amber wounded,
 * grey unconscious, black killed or off the net. A player scanning this rail is
 * looking for the one row that is not green, and that is a job colour does in
 * one glance and a number does not. The swatches stay square, like everything
 * else in the system.
 *
 * ACE's medical state is used when it is there and the engine's damage when it
 * is not, so the rail reads the same on a mission that does not load ACE.
 *
 * The strength count goes in the header rather than in a row, because it is the
 * answer to a different question from any single man's state. It used to get
 * there by overwriting the frame's own title control with a two-span markup -
 * the shell owns that control now and takes the readout through headerMeta.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel id <STRING>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_id", "", [""]]];

if (isNull _body) exitWith {};

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _scale = EGVAR(tacpad,textScale);
private _rowH = ROW_H * _scale * HOST_H;
private _w = (ctrlPosition _body) # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

private _units = (units group player) select {alive _x || {!isNull _x}};
private _alive = {alive _x} count _units;

private _iconH = _rowH * 0.62;
private _iconW = _iconH * pixelW / pixelH;

// The body is a scrolling controls group and its bar sits inside the right edge.
// Content that runs to _w runs underneath it.
private _scrollW = 14 * pixelW;

// THE RAIL KEEPS THE HEIGHT IT WAS PLACED AT, like the reader, and the legend
// and REFRESH are pinned to the foot of it. Both other answers were wrong and
// both were shipped: sized to sixteen rows it ran off the bottom of the screen
// and sat on the chat overlay, and sized to the men actually in it a four-man
// team got a rail two inches tall. A rail is a rail - the roster inside it
// scrolls, and the buttons stay where the player last saw them.
private _bodyH = (ctrlPosition _body) # 3;
private _legendH = _iconH + _rowH * 0.7;
// THE RAIL'S TYPE IS TWO PIXELS UP on the rest of the apps' (user,
// 2026-10-22: "increase the fonts in the squad screen ... 2px larger"): the
// rows, the legend and REFRESH, and the health figure by the same two.
private _rowText = [TEXT_BODY, APP_TEXT_UP_PX] call EFUNC(tacpad,textPx);
private _smallText = [TEXT_LABEL, APP_TEXT_UP_PX] call EFUNC(tacpad,textPx);
private _figureText = [TEXT_TITLE, TEXT_UP_PX] call EFUNC(tacpad,textPx);
private _refreshH = ([_rowText] call EFUNC(tacpad,textH)) + 2 * _padY;
private _footH = _legendH + _refreshH + _padY * 3;
private _footY = _bodyH - _footH;

// What fits above the foot. Nothing is drawn under the pinned buttons - a name
// hidden behind a legend is worse than a name that is not drawn at all, and the
// header's own N / M readout says how many there are either way.
private _fits = 0 max floor ((_footY - _padY) / _rowH);

private _row = 0;
{
    private _unit = _x;

    private _uncon = if (isNil QEFUNC(common,isUnconscious)) then {
        lifeState _unit == "INCAPACITATED"
    } else {
        [_unit] call EFUNC(common,isUnconscious)
    };

    // The number is what the swatch is standing for, so they can never disagree:
    // both come off the same damage read.
    private _health = round ((1 - damage _unit) * 100);

    (switch (true) do {
        case (!alive _unit): {[ICON_KIA, true]};
        case (_uncon): {[ICON_UNCON, true]};
        case (_health < 75): {[ICON_WIA, true]};
        default {[ICON_OK, false]};
    }) params ["_icon", "_hurt"];

    private _y = _row * _rowH;
    private _self = _unit isEqualTo player;

    [_body, [_pad, _y + (_rowH - _iconH) * 0.5, _iconH], _icon] call EFUNC(tacpad,drawIcon);

    // ACCENT MEANS SOMETHING IS WRONG. It used to mark whichever row was you,
    // which is the one thing on the rail you already know - so a rail with a
    // healthy section had a red row on it permanently and a red row stopped
    // meaning anything. You are marked in bold instead.
    [
        _body,
        [_pad * 2 + _iconW, _y, _w * 0.72 - _pad, _rowH],
        format ["%1 %2", [rank _unit] call EFUNC(tacpad,rankShort), name _unit],
        _ink,
        // The body size plus the rail's two pixels. The rail was once set a
        // third larger than everything beside it, which made a five-man
        // section look like it needed half the screen.
        _rowText, _self
    ] call EFUNC(tacpad,drawText);

    // A NUMBER ONLY WHEN IT MEANS SOMETHING. A column of 100s down a healthy
    // section is a column asking to be read and then ignored; the figure is the
    // one thing on the row that changes, so it appears when it has changed.
    // The scrollbar owns the right edge of a scrolling group, so the column
    // stops short of it rather than being clipped in half by it.
    if (_hurt) then {
        [
            _body,
            [_w * 0.72, _y, _w * 0.28 - _scrollW - _pad, _rowH],
            [str _health, "-"] select (!alive _unit || _uncon),
            _accent,
            _figureText, true, "right"
        ] call EFUNC(tacpad,drawText);
    };

    [_body, [_pad, _y + _rowH - RULE_THIN * pixelH, _w - 2 * _pad, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

    // THE ROW IS THE WAY IN. A rail with a row per man and a separate OPEN FULL
    // LIST button underneath it spent a row of a sixteen-man rail on saying what
    // pressing the rail already means.
    private _hit = [_body, [0, _y, _w, _rowH], {
        params ["_ctrl"];
        // The selection, written directly - the QGVAR(squadRow) localEvent
        // this used to raise had no listener anywhere, so pressing a man
        // opened the app with nobody selected. appSquad reads this.
        GVAR(squadSelected) = _ctrl getVariable [QGVAR(unit), objNull];
        ["squad", [], true] call EFUNC(tacpad,openApp);
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(unit), _unit];

    _row = _row + 1;
} forEach (_units select [0, ROSTER_MAX min _fits]);

[_id, format ["%1 / %2", _alive, count _units], _alive < count _units] call EFUNC(tacpad,headerMeta);

// Said, not swallowed: a rail too short for the section says how many it could
// not draw rather than quietly showing the first few.
private _hidden = (count _units) - _row;
if (_hidden > 0) then {
    // The full roster is one press away and scrolls - panels are a fixed
    // size, so pointing at the list is the only useful thing to say.
    [
        _body, [_pad, _row * _rowH, _w - 2 * _pad - _scrollW, _rowH],
        format ["+%1 MORE - PRESS A ROW FOR THE FULL LIST", _hidden], _mute, _smallText, true, "left", true
    ] call EFUNC(tacpad,drawText);
};

// ------------------------------------------------------------- the feet -----
// Pinned to the foot of the rail, not floated under the last man - so the legend
// and REFRESH are where the player last saw them however many men are in the
// section. See the note where _footY is worked out.
private _legendY = _footY + _padY;
private _cellW = (_w - 2 * _pad) / 4;

[_body, [_pad, _footY - _padY, _w - 2 * _pad - _scrollW, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
// LABEL UNDER GLYPH. Side by side, UNCON had to wrap inside its own cell and
// broke as "UNC / ON"; stacked, each pair gets the full cell width for its word.
{
    _x params ["_label", "_icon"];
    private _lx = _pad + _forEachIndex * _cellW;
    [_body, [_lx + (_cellW - _iconW) * 0.5, _legendY, _iconH] , _icon] call EFUNC(tacpad,drawIcon);
    [_body, [_lx, _legendY + _iconH, _cellW, _rowH * 0.7], _label, _mute, _smallText, true, "center", true] call EFUNC(tacpad,drawText);
} forEach [
    ["OK", ICON_OK],
    ["WIA", ICON_WIA],
    ["UNCON", ICON_UNCON],
    ["KIA", ICON_KIA]
];

// REFRESH. The rail redraws itself on the shell's timer, but a roster is the one
// panel where a player has a reason to distrust that - somebody has just joined,
// or changed slot, and waiting two seconds to find out whether it noticed is two
// seconds of not knowing. It also re-reads the group, which is what actually
// changes when a man is moved between sections.
private _refreshY = _legendY + _legendH + _padY * 0.5;

[_body, [_pad, _refreshY, _w - 2 * _pad - _scrollW, _refreshH], _ink, RULE_THIN] call EFUNC(tacpad,drawFrame);
[_body, [_pad * 2, _refreshY, _w - 3 * _pad - _scrollW, _refreshH], "REFRESH", _mute, _rowText, true, "center", true] call EFUNC(tacpad,drawText);
[_body, [_pad, _refreshY, _w - 2 * _pad - _scrollW, _refreshH], {
    {["squad"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

// NO fit. The rail is a docked rail and keeps its placed height - the same
// rule the reader beside it follows.
