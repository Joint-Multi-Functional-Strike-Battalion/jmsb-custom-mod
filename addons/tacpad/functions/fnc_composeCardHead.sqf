#include "script_component.hpp"
/*
 * Author: YonV
 * The top of a report card, the handoff's anatomy (design_handoff_report_forms):
 * the header - a tag box with the template's short name and the full title
 * beside it, over a 2px ink rule - and under it the badge strip, the card's
 * facts on the surface fill.
 *
 * THE TAG IS INK, AND ACCENT FOR A HIGH-PRIORITY TEMPLATE. The handoff names
 * CASEVAC, TIC, CFF, CAS and CANTCO; which templates those are is not written
 * here - it is the template's own priority (the PAC deck's "high - FLASH"), so
 * a unit that makes another report FLASH gets the red tag with it.
 *
 * THE STRIP SAYS WHAT SENDING THIS DOES - the task it opens, where it anchors
 * on the map, who else it reaches, who may send it - once, at the top, rather
 * than discovered after SEND.
 *
 * REAL WORLD / SIMPLE (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09): a card with a
 * short form (its shortKeys) carries the switch at the header's right end -
 * one card, two views, the same keys. A press flips GVAR(composeShortOn) for
 * this card; FUNC(composeCard) draws only the short form's fields while it is
 * on. A FRAGO's card reads FRAGO: <TITLE> (FUNC(composeFrago)).
 *
 * Arguments:
 * 0: Group the card is drawn into <CONTROL>
 * 1: Template <HASHMAP>
 * 2: Width of the card <NUMBER>
 *
 * Return Value:
 * Height used <NUMBER>
 *
 * Example:
 * private _h = [_body, _template, _w] call jmfsb_tacpad_fnc_composeCardHead
 *
 * Public: No
 */

params [
    ["_body", controlNull, [controlNull]],
    ["_template", createHashMap, [createHashMap]],
    ["_w", 0, [0]]
];

if (isNull _body) exitWith {0};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent"];
private _surface = ["surface"] call FUNC(theme);
private _muted = ["muted"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

// ---------------------------------------------------------------- header ---
private _short = toUpper (_template getOrDefault ["short", _template getOrDefault ["id", ""]]);
private _title = toUpper (_template getOrDefault ["title", _short]);
if (GVAR(composeFrago) isNotEqualTo []) then {_title = format [FRAGO_TITLE, _title]};
private _hasShort = (_template getOrDefault ["shortKeys", []]) isNotEqualTo [];
private _high = (_template getOrDefault ["priority", "normal"]) isEqualTo CARD_PRIORITY_HIGH;

private _tagH = ([CARD_TAG_SIZE] call FUNC(textH)) + _padY;
private _headH = ([CARD_TITLE_SIZE] call FUNC(textH)) + 2 * _padY;
private _glyph = ([CARD_TAG_SIZE] call FUNC(textH)) / 1.25 * CARD_GLYPH_W * pixelW / pixelH;
private _tagW = ((count _short) * _glyph + 2 * _pad) min (_w * CARD_TAG_MAX_W);
private _tagY = (_headH - _tagH) * 0.5;

[_body, [0, _tagY, _tagW, _tagH], [_ink, _accent] select _high] call FUNC(drawFill);
[_body, [0, _tagY, _tagW, _tagH], _short, _ground, CARD_TAG_SIZE, true, "center"] call FUNC(drawText);
private _switchW = [0, _w * SHORT_SWITCH_W] select _hasShort;
[_body, [_tagW + _pad * 2, 0, _w - _tagW - _pad * 3 - _switchW, _headH], _title, _ink, CARD_TITLE_SIZE, true] call FUNC(drawText);

// The REAL WORLD / SIMPLE switch: two segments, the view on is the ink fill.
if (_hasShort) then {
    private _segW = _switchW / 2;
    {
        _x params ["_word", "_isShort"];
        private _sx = _w - _switchW + _forEachIndex * _segW;
        private _on = GVAR(composeShortOn) isEqualTo _isShort;
        if (_on) then {
            [_body, [_sx, _tagY, _segW, _tagH], _ink] call FUNC(drawFill);
        } else {
            [_body, [_sx, _tagY, _segW, _tagH], _ink, RULE_THIN] call FUNC(drawFrame);
        };
        [_body, [_sx, _tagY, _segW, _tagH], _word, [_ink, _ground] select _on, CARD_TAG_SIZE, true, "center"] call FUNC(drawText);
        private _hit = [_body, [_sx, _tagY, _segW, _tagH], {
            params ["_ctrl"];
            [] call FUNC(composeHarvest);
            GVAR(composeShortOn) = _ctrl getVariable [QGVAR(shortView), false];
            {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
        }] call FUNC(drawHit);
        _hit setVariable [QGVAR(shortView), _isShort];
    } forEach [[STD_WORD, false], [SHORT_WORD, true]];
};
[_body, [0, _headH, _w, RULE_THICK * pixelH], _ink] call FUNC(drawFill);

private _y = _headH + RULE_THICK * pixelH;

// ------------------------------------------------------------ badge strip ---
private _badges = [];
private _lines = _template getOrDefault ["lines", []];
private _transitions = _template getOrDefault ["transitionsTo", ""];
if (_transitions isNotEqualTo "") then {_badges pushBack format ["OPENS TASK - %1", _transitions]};

private _anchorKey = ((_template getOrDefault ["anchor", ""]) splitString ".") param [0, ""];
if (_anchorKey isNotEqualTo "") then {
    private _ai = _lines findIf {(_x param [0, ""]) isEqualTo _anchorKey};
    if (_ai > -1) then {
        _badges pushBack format ["MAP ANCHOR - %1", toUpper ((_lines # _ai) param [1, _anchorKey])];
    };
};

if ((_template getOrDefault ["broadcast", ""]) isNotEqualTo "") then {
    _badges pushBack format ["BROADCAST - %1", toUpper (_template get "broadcast")];
};
if ((_template getOrDefault ["reportable", ""]) isNotEqualTo "") then {
    _badges pushBack format ["ALIVE FWD - %1", toUpper (_template get "reportable")];
};
if ((_template getOrDefault ["routing", ""]) isNotEqualTo "") then {_badges pushBack "ROUTING - CMD TICK"};
if ((_template getOrDefault ["kind", "root"]) isEqualTo "both") then {_badges pushBack "ROOT + REPLY"};

// The sender constraint, as the handoff prints it on CANTCO and CLOSE.
private _mustBe = _template getOrDefault ["senderMustBe", "any"];
if (_mustBe in ["issuer", "assignee", "leader"]) then {_badges pushBack format ["%1 ONLY", toUpper _mustBe]};

if (_badges isEqualTo []) exitWith {_y + _padY};

private _stripH = ([CARD_BADGE_SIZE] call FUNC(textH)) + 2 * _padY;
[_body, [0, _y, _w, _stripH], _surface] call FUNC(drawFill);
[_body, [_pad, _y, _w - 2 * _pad, _stripH], _badges joinString "   ", _muted, CARD_BADGE_SIZE, true] call FUNC(drawText);

_y + _stripH + _padY
