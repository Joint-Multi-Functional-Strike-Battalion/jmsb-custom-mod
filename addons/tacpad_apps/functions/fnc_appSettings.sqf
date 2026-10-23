#include "script_component.hpp"
/*
 * Author: JMSB
 * The settings app, built to the design: a section rail down the left, the
 * chosen section's controls in the pane beside it.
 *
 * It was one flat list of eleven rows. The design splits it because the colour
 * scheme is not a row - it is four preset cards you compare against each other
 * and three tokens everything else derives from - and a list cannot show a
 * scheme without describing it in words.
 *
 * It writes the same CBA settings that Addon Options writes, so a change made
 * here is the change made there - there is one set of values, not an in-game
 * set and a menu set that can disagree. A setting the server or mission forces
 * is drawn read-only, LOCKED (FUNC(settingLocked)).
 *
 * Other addons add sections after these (GVAR(settingsSections)): the phone
 * and side devices' DEVICES and DEVICE KEYS come from jmfsb_devices, which owns
 * their ranges and choices.
 *
 * Arguments:
 * 0: Map display <DISPLAY>
 * 1: App id <STRING>
 * 2: Arguments - the section to open on <ARRAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_app", "", [""]], ["_args", [], [[]]]];

if (isNull _display) exitWith {};

private _section = _args param [0, GVAR(settingsSection)];
GVAR(settingsSection) = _section;

// Taller than it was: six preset cards and three wrapped swatch strips are more
// screen than four cards and three single rows, and a settings screen that runs
// off its own foot is worse than one that takes the room.
([_display, "SETTINGS", 0.66, 0.80] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pos = ctrlPosition _body;
private _w = _pos # 2;
private _h = _pos # 3;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

// ---------------------------------------------------------------- the rail --
private _railW = _w * 0.24;
private _navH = _rowH * 1.4;

{
    _x params ["_key", "_label"];
    private _on = _key == _section;
    private _y = _forEachIndex * _navH;

    if (_on) then {
        [_body, [0, _y, _railW, _navH], _accent] call EFUNC(tacpad,drawFill);
    };
    [_body, [_pad * 2, _y, _railW - _pad * 3, _navH], _label, ([_ink, _ground] select _on), TEXT_TITLE, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [0, _y + _navH - RULE_THIN * pixelH, _railW, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

    // Next frame, because reopening the app deletes the button whose handler is
    // still running.
    private _hit = [_body, [0, _y, _railW, _navH], {
        params ["_ctrl"];
        [
            {["settings", [_this]] call EFUNC(tacpad,openApp)},
            _ctrl getVariable [QGVAR(section), "scheme"]
        ] call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(section), _key];
} forEach (([
    ["scheme", "COLOUR SCHEME"],
    ["panels", "PANELS"],
    ["tiles", "LIVE TILES"],
    ["nets", "NETS & ALERTS"],
    ["tools", "MAP TOOLS"],
    ["size", "UI SIZE"],
    ["text", "TEXT SIZE"]
] select {
    // NO MAP TOOLS ADDON, NO SECTION. Its one row toggles a panel that cannot
    // exist without jmfsb_maptools - see the tools registration in
    // XEH_preInit. A settings page whose switch does nothing is worse than one
    // without it.
    (_x # 0) isNotEqualTo "tools" || {!isNil QEFUNC(maptools,start)}
}) + (GVAR(settingsSections) apply {[_x # 0, _x # 1]}));

// A 2px rule between the rail and the pane - a region boundary, not a row one.
[_body, [_railW, 0, RULE_THICK * pixelW, _h], _ink] call EFUNC(tacpad,drawFill);

private _px = _railW + RULE_THICK * pixelW + _pad * 2;
private _pw = _w - _px - _pad * 2;

// -------------------------------------------------------------- the scheme --
if (_section == "scheme") exitWith {
    private _y = _padY;

    // Each card is its own three tokens shown as three bands over a name plate,
    // which is the only honest way to offer a scheme: the swatch IS the scheme.
    //
    // THREE UP - the shipped presets run day grounds above their own night ones,
    // so the pair a unit actually switches between sits in one column.
    //
    // ONE DRAWER FOR BOTH LISTS. The mission's presets are drawn with this too,
    // because a unit palette that looked like a lesser control than FIELD GREY
    // would read as a second-class way to set the same three tokens - which it
    // is not. Each card is [label, ground, ink, accent, active, press, vars].
    private _fnc_cards = {
        params ["_cards", "_y"];

        private _perRow = 3;
        private _cardW = (_pw - (_perRow - 1) * _pad) / _perRow;
        private _cardH = _rowH * 2;
        private _plateH = _rowH * 0.9;
        private _bandH = _cardH - _plateH;

        {
            _x params ["_label", "_g", "_i", "_a", "_on", "_press", "_vars"];
            private _cx = _px + (_forEachIndex % _perRow) * (_cardW + _pad);
            private _cy = _y + floor (_forEachIndex / _perRow) * (_cardH + _pad);

            [_body, [_cx, _cy, _cardW * 0.5, _bandH], _g] call EFUNC(tacpad,drawFill);
            [_body, [_cx + _cardW * 0.5, _cy, _cardW * 0.25, _bandH], _i] call EFUNC(tacpad,drawFill);
            [_body, [_cx + _cardW * 0.75, _cy, _cardW * 0.25, _bandH], _a] call EFUNC(tacpad,drawFill);

            [_body, [_cx, _cy, _cardW, _cardH], ([_ink, _accent] select _on), RULE_THICK] call EFUNC(tacpad,drawFrame);
            [_body, [_cx + _pad, _cy + _bandH, _cardW * 0.62, _plateH], _label, _ink, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);

            if (_on) then {
                [_body, [_cx + _cardW * 0.62, _cy + _bandH, _cardW * 0.38 - _pad, _plateH], "ACTIVE", _accent, TEXT_LABEL, true, "right", true] call EFUNC(tacpad,drawText);
            };

            // The card's own data travels on the hit control, because the block
            // runs long after the draw that made it.
            private _hit = [_body, [_cx, _cy, _cardW, _cardH], _press] call EFUNC(tacpad,drawHit);
            {
                _hit setVariable [_x # 0, _x # 1];
            } forEach _vars;
        } forEach _cards;

        _y + ceil ((count _cards) / _perRow) * (_cardH + _pad)
    };

    [_body, [_px, _y, _pw, _rowH], "PRESETS", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;

    _y = [
        [
            ["jmsb", "JMSB DAY", [0.914, 0.894, 0.831, 1], [0.125, 0.149, 0.110, 1], [0.541, 0.459, 0.314, 1]],
            ["light", "FIELD GREY", [0.953, 0.949, 0.949, 1], [0.125, 0.118, 0.114, 1], [0.925, 0.188, 0.075, 1]],
            ["olive", "OLIVE", [0.910, 0.906, 0.886, 1], [0.086, 0.157, 0.114, 1], [0.710, 0.800, 0.290, 1]],
            ["sand", "SAND", [0.937, 0.925, 0.894, 1], [0.169, 0.129, 0.098, 1], [0.851, 0.580, 0.153, 1]],
            ["nightJmsb", "JMSB NIGHT", [0.125, 0.149, 0.110, 1], [0.914, 0.894, 0.831, 1], [0.761, 0.659, 0.471, 1]],
            ["dark", "NIGHT / RED", [0.078, 0.082, 0.078, 1], [0.902, 0.898, 0.886, 1], [1, 0.337, 0.235, 1]],
            ["nightOlive", "NIGHT OLIVE", [0.063, 0.078, 0.067, 1], [0.851, 0.878, 0.831, 1], [0.612, 0.706, 0.235, 1]],
            ["nightSand", "NIGHT SAND", [0.086, 0.075, 0.063, 1], [0.898, 0.878, 0.839, 1], [0.780, 0.510, 0.129, 1]]
        ] apply {
            _x params ["_key", "_label", "_g", "_i", "_a"];
            [
                _label, _g, _i, _a, _key == EGVAR(tacpad,scheme),
                {
                    params ["_ctrl"];
                    [QEGVAR(tacpad,scheme), _ctrl getVariable [QGVAR(preset), "light"]] call FUNC(setSetting);
                },
                [[QGVAR(preset), _key]]
            ]
        },
        _y
    ] call _fnc_cards;

    // --------------------------------------------------- the mission's own --
    // A UNIT PALETTE IS MISSION DATA. These come out of the mission's
    // config\config_tacpad.hpp, so a unit sets its colours once for everyone
    // playing rather than asking twenty people to reassemble the same three
    // tokens off the swatch strips below. A mission with nothing to say about
    // colour draws no row at all.
    //
    // Each one IS the custom scheme: pressing it writes the three tokens and
    // switches to custom, which is why the active test is the tokens matching
    // and not a scheme name - nothing downstream learns a seventh scheme.
    private _mission = call FUNC(missionSchemes);

    if (_mission isNotEqualTo []) then {
        _y = _y + _padY;
        [_body, [_px, _y, _pw, _rowH], "MISSION PRESETS", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
        _y = _y + _rowH;

        private _fnc_bare = {toUpper (_this splitString " #" joinString "")};
        private _now = [QEGVAR(tacpad,customGround), QEGVAR(tacpad,customInk), QEGVAR(tacpad,customAccent)] apply {
            (missionNamespace getVariable [_x, ""]) call _fnc_bare
        };
        private _isCustom = EGVAR(tacpad,scheme) == "custom";

        _y = [
            _mission apply {
                _x params ["_label", "_g", "_i", "_a"];
                [
                    _label,
                    [_g] call EFUNC(tacpad,rgbOf),
                    [_i] call EFUNC(tacpad,rgbOf),
                    [_a] call EFUNC(tacpad,rgbOf),
                    _isCustom && {_now isEqualTo ([_g, _i, _a] apply {_x call _fnc_bare})},
                    {
                        params ["_ctrl"];
                        // The three tokens are written quietly and the scheme
                        // switch applies them, so the suite rebuilds once.
                        {
                            [_x # 0, _x # 1, false] call FUNC(setSetting);
                        } forEach (_ctrl getVariable [QGVAR(tokens), []]);
                        [QEGVAR(tacpad,scheme), "custom"] call FUNC(setSetting);
                    },
                    [[QGVAR(tokens), [
                        [QEGVAR(tacpad,customGround), _g],
                        [QEGVAR(tacpad,customInk), _i],
                        [QEGVAR(tacpad,customAccent), _a]
                    ]]]
                ]
            },
            _y
        ] call _fnc_cards;
    };

    _y = _y + _padY;
    [_body, [_px, _y, _pw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
    _y = _y + _padY * 2;

    // ------------------------------------------------------ the three tokens --
    // PICKED, NOT TYPED. The design draws a hex field per token, and a hex field
    // on the map display means an edit control taking keyboard focus off the map
    // - so this offers a row of swatches per token instead. It is the same three
    // tokens and the same result; you just cannot spell one wrong.
    [_body, [_px, _y, _pw, _rowH], "CUSTOM - THREE TOKENS", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;

    {
        _x params ["_label", "_setting", "_swatches"];

        private _current = toUpper ((missionNamespace getVariable [_setting, ""]) splitString " #" joinString "");

        [_body, [_px, _y, _pw * 0.18, _rowH * 1.1], _label, _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);

        private _stripX = _px + _pw * 0.18;
        private _stripW = _pw - _pw * 0.18;

        // EIGHT ACROSS, THEN WRAP. Sixteen accents in one strip is sixteen
        // slivers - a swatch has to be big enough to judge the colour by.
        private _perRow = 8;
        private _swW = _stripW / _perRow;
        private _swH = _rowH * 0.95;
        private _swRows = ceil ((count _swatches) / _perRow);

        {
            private _hex = _x;
            private _on = _current == _hex;
            private _sx = _stripX + (_forEachIndex % _perRow) * _swW;
            private _sy = _y + floor (_forEachIndex / _perRow) * (_swH + _padY * 0.5);

            [_body, [_sx, _sy, _swW - _pad, _swH], [_hex] call EFUNC(tacpad,rgbOf)] call EFUNC(tacpad,drawFill);
            [
                _body, [_sx, _sy, _swW - _pad, _swH],
                ([_line, _accent] select _on),
                ([RULE_THIN, RULE_THICK] select _on)
            ] call EFUNC(tacpad,drawFrame);

            private _hit = [_body, [_sx, _sy, _swW - _pad, _swH], {
                params ["_ctrl"];
                // The token is written quietly and the scheme switch applies
                // both, so the suite rebuilds once rather than twice.
                [_ctrl getVariable [QGVAR(tokenSetting), ""], _ctrl getVariable [QGVAR(tokenHex), ""], false] call FUNC(setSetting);
                [QEGVAR(tacpad,scheme), "custom"] call FUNC(setSetting);
            }] call EFUNC(tacpad,drawHit);
            _hit setVariable [QGVAR(tokenSetting), _setting];
            _hit setVariable [QGVAR(tokenHex), format ["#%1", _hex]];
        } forEach _swatches;

        _y = _y + _swRows * (_swH + _padY * 0.5) + _padY * 0.5;
    } forEach [
        // Day grounds, then night ones. The two rows under it carry twice as
        // many: text and accent are the two tokens people actually want a say
        // in, and eight of each was two greys, two reds and no choice at all.
        ["GROUND", QEGVAR(tacpad,customGround), [
            "F3F2F2", "FAF9F6", "E8E7E2", "EFECE4", "E3E6E8", "EDE7F0",
            "141514", "0A0A0A", "1C1F21", "10180F", "241D16", "0E1620"
        ]],
        ["TEXT", QEGVAR(tacpad,customInk), [
            "201E1D", "0A0A0A", "16281D", "2B2119", "12243A", "3A1220",
            "E6E5E2", "FFFFFF", "CFCDC8", "D8E0D2", "E8DCC8", "9FC6E8",
            "7DE08A", "F2C14E", "FF9E80", "B8A6FF"
        ]],
        ["ACCENT", QEGVAR(tacpad,customAccent), [
            "EC3013", "FF563C", "C1121F", "D99427", "F2A93B", "B5CC4A",
            "9CB023", "4CAF50", "2FB8C6", "3D8BD8", "5C7CFA", "9B7BD4",
            "D6539B", "FF7AB6", "8C8C8C", "FFFFFF"
        ]]
    ];

    _y = _y + _padY;
    [
        _body, [_px, _y, _pw, _rowH],
        "DIVIDERS, TINTS AND PRESSED STATES DERIVE FROM THESE THREE - NOTHING ELSE IS SET BY HAND",
        _mute, TEXT_LABEL, true, "left", true
    ] call EFUNC(tacpad,drawText);

    _y = _y + _rowH + _padY;
    [_body, [_px, _y, _pw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
    _y = _y + _padY * 2;

    // ------------------------------------------------- what is never themed --
    [_body, [_px, _y, _pw, _rowH], "FIXED - STATUS COLOURS ARE NEVER THEMED", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;

    private _fixW = _pw / 4;
    private _iconH = _rowH * 0.7;
    {
        _x params ["_label", "_icon"];
        private _fx = _px + _forEachIndex * _fixW;
        [_body, [_fx, _y + (_rowH - _iconH) * 0.5, _iconH], _icon] call EFUNC(tacpad,drawIcon);
        [_body, [_fx + _iconH * pixelW / pixelH + _pad, _y, _fixW - _iconH, _rowH], _label, _mute, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    } forEach [
        ["OK", ICON_OK],
        ["WIA", ICON_WIA],
        ["UNCON", ICON_UNCON],
        ["KIA", ICON_KIA]
    ];

    // ------------------------------------------------------------- the foot --
    private _footH = _rowH * 1.3;
    private _footY = _h - _footH - _padY;
    [_body, [_px, _footY - _padY, _pw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

    private _btnW = _pw * 0.3;
    [_body, [_px, _footY, _btnW, _footH], _accent] call EFUNC(tacpad,drawFill);
    [_body, [_px + _pad, _footY, _btnW - 2 * _pad, _footH], "APPLY TO ALL PANELS", _ground, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);
    [_body, [_px, _footY, _btnW, _footH], {
        [] call EFUNC(tacpad,open);
    }] call EFUNC(tacpad,drawHit);

    private _resetX = _px + _btnW + _pad;
    [_body, [_resetX, _footY, _btnW, _footH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
    [_body, [_resetX + _pad, _footY, _btnW - 2 * _pad, _footH], "RESET TO FIELD GREY", _ink, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);
    [_body, [_resetX, _footY, _btnW, _footH], {
        [QEGVAR(tacpad,scheme), "light"] call FUNC(setSetting);
    }] call EFUNC(tacpad,drawHit);

    [
        _body, [_resetX + _btnW + _pad, _footY, _pw - 2 * _btnW - 2 * _pad, _footH],
        "SAVED PER PLAYER PROFILE", _mute, TEXT_LABEL, true, "right", true
    ] call EFUNC(tacpad,drawText);
};

// ---------------------------------------------------------------- UI size --
// SHRINK AND GROW, IN THE STEPS PEOPLE ACTUALLY WANT. A slider is the setting
// underneath and stays in Addon Options for anyone who wants a number; this is
// six buttons, because "a bit smaller" is a press and not a value to look up.
if (_section == "size") exitWith {
    private _y = _padY;
    private _pct = round (EGVAR(tacpad,uiScale) * 100);

    [_body, [_px, _y, _pw, _rowH], "UI SIZE", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_px, _y, _pw, _rowH], format ["%1%2", _pct, "%"], _accent, TEXT_TITLE, true, "right"] call EFUNC(tacpad,drawText);
    _y = _y + _rowH * 1.2;

    [
        _body, [_px, _y, _pw, _rowH],
        "PANELS, ROWS AND TYPE TOGETHER - TEXT SIZE IS ITS OWN SECTION",
        _mute, TEXT_LABEL, true, "left", true
    ] call EFUNC(tacpad,drawText);
    _y = _y + _rowH * 1.2;

    private _btnH = ([TEXT_TITLE] call EFUNC(tacpad,textH)) + 2 * _padY;
    private _stepW = (_pw - 2 * _pad) / 3;

    {
        _x params ["_label", "_rows"];

        [_body, [_px, _y, _pw, _rowH], _label, _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
        _y = _y + _rowH;

        {
            _x params ["_text", "_factor"];
            private _sx = _px + _forEachIndex * (_stepW + _pad);

            [_body, [_sx, _y, _stepW, _btnH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
            [_body, [_sx, _y, _stepW, _btnH], _text, _ink, TEXT_TITLE, true, "center"] call EFUNC(tacpad,drawText);

            private _hit = [_body, [_sx, _y, _stepW, _btnH], {
                params ["_ctrl"];
                private _f = _ctrl getVariable [QGVAR(scaleFactor), 1];

                // Clamped to the setting's own range, and rounded to the
                // hundredth the slider stores - so stepping down and back up
                // lands on the number it started at rather than near it.
                private _next = 0.5 max (2 min (round (EGVAR(tacpad,uiScale) * _f * 100) / 100));
                [QEGVAR(tacpad,uiScale), _next] call FUNC(setSetting);
            }] call EFUNC(tacpad,drawHit);
            _hit setVariable [QGVAR(scaleFactor), _factor];
        } forEach _rows;

        _y = _y + _btnH + _padY * 1.5;
    } forEach [
        ["SHRINK", [["- 1%", 0.99], ["- 5%", 0.95], ["- 10%", 0.90]]],
        ["GROW", [["+ 1%", 1.01], ["+ 5%", 1.05], ["+ 10%", 1.10]]]
    ];

    [_body, [_px, _y, _pw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
    _y = _y + _padY * 2;

    private _resetW = _pw * 0.4;
    [_body, [_px, _y, _resetW, _btnH], _accent] call EFUNC(tacpad,drawFill);
    [_body, [_px, _y, _resetW, _btnH], "RESET TO 100%", _ground, TEXT_TITLE, true, "center"] call EFUNC(tacpad,drawText);
    [_body, [_px, _y, _resetW, _btnH], {
        [QEGVAR(tacpad,uiScale), 1] call FUNC(setSetting);
    }] call EFUNC(tacpad,drawHit);

    [
        _body, [_px + _resetW + _pad, _y, _pw - _resetW - _pad, _btnH],
        "SAVED PER PLAYER PROFILE", _mute, TEXT_LABEL, true, "right", true
    ] call EFUNC(tacpad,drawText);
};

// ------------------------------------------------------ everything else -----
// The remaining sections are lists of toggles, which is what a toggle wants to
// be. Each row is [label, current value, what pressing it does], and optionally
// the press that steps it down (a minus / plus pair), whether the setting is
// forced (drawn LOCKED, no controls) and the pair's two glyphs. A row whose
// press is {} is a line to read, not a control.
private _fnc_onOff = {["OFF", "ON"] select _this};

private _rows = switch (_section) do {
    case "panels": {
        [
            ["SHOW SQUAD LIST", GVAR(show_squad) call _fnc_onOff, {
                [QGVAR(show_squad), !GVAR(show_squad)] call FUNC(setSetting);
            }],
            ["SHOW TROOPS IN CONTACT BUTTON", GVAR(show_tic) call _fnc_onOff, {
                [QGVAR(show_tic), !GVAR(show_tic)] call FUNC(setSetting);
            }],
            ["KEEP CLEAR OF RESERVED AREAS", EGVAR(tacpad,respectZones) call _fnc_onOff, {
                [QEGVAR(tacpad,respectZones), !EGVAR(tacpad,respectZones)] call FUNC(setSetting);
            }]
        ]
    };
    case "tiles": {
        [
            ["SHOW LIVE TILES", GVAR(show_tiles) call _fnc_onOff, {
                [QGVAR(show_tiles), !GVAR(show_tiles)] call FUNC(setSetting);
            }]
        ]
    };
    case "nets": {
        private _list = [
            ["SHOW MESSAGE READER", GVAR(show_reader) call _fnc_onOff, {
                [QGVAR(show_reader), !GVAR(show_reader)] call FUNC(setSetting);
            }],
            ["READER: HIGH DENSITY", GVAR(readerDense) call _fnc_onOff, {
                [QGVAR(readerDense), !GVAR(readerDense)] call FUNC(setSetting);
            }],
            // On demand, not only at join. A setting that seeds three threads
            // when you connect cannot be used to test the thing you just changed.
            ["SEND TEST TRAFFIC", "NOW", {
                if (isNil QEFUNC(messaging,seedTest)) exitWith {};
                [] call EFUNC(messaging,seedTest);
            }]
        ];

        // THE SUBSCRIPTION ROWS the handoff asks for: one per shared net,
        // ALERT or MUTED, kept on the player's profile. A muted net still
        // badges - the rail's unread counts always move - and FLASH traffic or
        // being called out by name always breaks through. Your own squad and
        // your own name are not subscriptions and are not offered.
        if (!isNil QEFUNC(messaging,setNetLevel)) then {
            _list pushBack ["YOUR SQUAD & DIRECT TRAFFIC", "ALERT - ALWAYS", {}];
            {
                private _net = _x;
                _list pushBack [
                    format ["NET - %1", toUpper _net],
                    ["ALERT", "MUTED"] select (
                        (missionNamespace getVariable [QEGVAR(messaging,netLevels), createHashMap])
                            getOrDefault [_net, 0] > 0
                    ),
                    compile format ["['%1'] call %2", _net, QFUNC(toggleNet)]
                ];
            } forEach ((EGVAR(messaging,namedBoxes) splitString ",") apply {trim _x} select {_x != ""});
        };
        _list
    };
    case "tools": {
        [
            ["SHOW MAP TOOLS", GVAR(show_tools) call _fnc_onOff, {
                [QGVAR(show_tools), !GVAR(show_tools)] call FUNC(setSetting);
            }]
        ]
    };
    default {
        [
            // STEPPERS, not cycles. These wrapped at the top of their range back
            // to the bottom, which is nineteen presses to make the text one step
            // smaller - so in practice they only went up. A fourth entry makes a
            // row a minus/plus pair, clamped to the slider's own range.
            ["TEXT SIZE", str EGVAR(tacpad,textScale), {
                [QEGVAR(tacpad,textScale), 2.5 min (round ((EGVAR(tacpad,textScale) + 0.1) * 100) / 100)] call FUNC(setSetting);
            }, {
                [QEGVAR(tacpad,textScale), 0.6 max (round ((EGVAR(tacpad,textScale) - 0.1) * 100) / 100)] call FUNC(setSetting);
            }],
            ["PANEL OPACITY", str EGVAR(tacpad,opacity), {
                [QEGVAR(tacpad,opacity), 1 min (round ((EGVAR(tacpad,opacity) + 0.05) * 100) / 100)] call FUNC(setSetting);
            }, {
                [QEGVAR(tacpad,opacity), 0.3 max (round ((EGVAR(tacpad,opacity) - 0.05) * 100) / 100)] call FUNC(setSetting);
            }]
        ]
    };
};

// A section another addon added (GVAR(settingsSections)) answers its own rows.
private _registered = GVAR(settingsSections) findIf {(_x # 0) isEqualTo _section};
if (_registered >= 0) then {
    _rows = call (GVAR(settingsSections) # _registered # 2);
};

{
    _x params ["_label", "_value", "_action", ["_down", {}], ["_locked", false], ["_glyphs", ["-", "+"]]];
    private _y = _padY + _forEachIndex * _rowH;
    private _stepper = _down isNotEqualTo {};

    [_body, [_px, _y, _pw * 0.6, _rowH], _label, _ink, TEXT_TITLE, false] call EFUNC(tacpad,drawText);
    [_body, [_px, _y + _rowH - RULE_THIN * pixelH, _pw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

    // FORCED BY THE SERVER OR MISSION: the value it is held at, muted, and
    // nothing to press - a control that does nothing is worse than none.
    if (_locked) then {
        [_body, [_px + _pw * 0.6, _y, _pw * 0.4, _rowH], format ["%1  %2", _value, SETTINGS_LOCKED], _mute, TEXT_TITLE, true, "right"] call EFUNC(tacpad,drawText);
        continue;
    };

    if (!_stepper) then {
        [_body, [_px + _pw * 0.6, _y, _pw * 0.4, _rowH], _value, _accent, TEXT_TITLE, true, "right"] call EFUNC(tacpad,drawText);

        if (_action isNotEqualTo {}) then {
            private _hit = [_body, [_px, _y, _pw, _rowH], {
                params ["_ctrl"];
                call (_ctrl getVariable [QGVAR(settingAction), {}]);
            }] call EFUNC(tacpad,drawHit);
            _hit setVariable [QGVAR(settingAction), _action];
        };
    } else {
        // MINUS, VALUE, PLUS. The value sits between the two so it reads as the
        // thing being changed rather than as a third button.
        private _stepW = _rowH * 1.1;
        private _minusX = _px + _pw - 2 * _stepW - _pad;
        private _plusX = _px + _pw - _stepW;
        private _valueW = _pw * SETTINGS_STEP_VALUE_W;

        [_body, [_minusX - _valueW - _pad, _y, _valueW, _rowH], _value, _accent, TEXT_TITLE, true, "right"] call EFUNC(tacpad,drawText);

        {
            _x params ["_sx", "_glyph", "_code"];

            [_body, [_sx, _y + _padY * 0.5, _stepW, _rowH - _padY], _ink, RULE_THIN] call EFUNC(tacpad,drawFrame);
            [_body, [_sx, _y, _stepW, _rowH], _glyph, _ink, TEXT_TITLE, true, "center"] call EFUNC(tacpad,drawText);

            private _hit = [_body, [_sx, _y + _padY * 0.5, _stepW, _rowH - _padY], {
                params ["_ctrl"];
                call (_ctrl getVariable [QGVAR(settingAction), {}]);
            }] call EFUNC(tacpad,drawHit);
            _hit setVariable [QGVAR(settingAction), _code];
        } forEach [
            [_minusX, _glyphs # 0, _down],
            [_plusX, _glyphs # 1, _action]
        ];
    };
} forEach _rows;
