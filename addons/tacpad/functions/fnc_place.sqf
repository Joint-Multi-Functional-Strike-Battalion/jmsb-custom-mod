#include "script_component.hpp"
/*
 * Author: JMSB
 * Where a panel actually goes: its default, clamped into the current safe zone
 * and pushed clear of the three regions the design says must never be covered -
 * or, on a device that handed over a layout table, its fixed place there.
 *
 * THE DEFAULT IS THE POSITION. Nothing stores a per-player one and nothing
 * reads one - a panel is where its DEFAULT_* define says, every session, on
 * every machine.
 *
 * The clamp is not politeness. A default written for a 16:9 screen puts a panel
 * off the edge of an ultrawide one, and a panel sitting on the chat overlay
 * costs a player the only text channel they have.
 *
 * Nudged rather than refused: a panel overlapping a reserved zone is slid the
 * shortest way clear.
 *
 * Arguments:
 * 0: Panel id <STRING>
 * 1: Default place [x, y, w, h] in safe-zone fractions <ARRAY>
 *
 * Return Value:
 * 0: Screen position [x, y, w, h] ready for ctrlSetPosition <ARRAY>
 * 1: The fractions it settled on <ARRAY>
 *
 * Example:
 * (["squad", DEFAULT_SQUAD] call jmfsb_tacpad_fnc_place) params ["_pos", "_fr"]
 *
 * Public: No
 */

params [["_id", "", [""]], ["_default", [0.1, 0.1, 0.2, 0.2], [[]], 4]];

private _fr = _default;

// A DEVICE'S FIXED PLACE WINS (docs/DESIGN_TABLET.md: "panels are not
// draggable on the tablet; their places are fixed"). The tablet hands its own
// layout table over with the host - see FUNC(setHost) - in fractions of its
// map area, and a panel it names goes exactly there: not scaled, because the
// table was drawn at the size the screen is, and not pushed by the reserved
// zones below, which are the vanilla map's furniture and not the device's.
private _hostPlace = GVAR(hostPlaces) getOrDefault [_id, []];
private _fixed = HOST_DEVICE && {_hostPlace isNotEqualTo []};
if (_fixed) then {
    _fr = _hostPlace;
};
_fr params ["_px", "_py", "_pw", "_ph"];

// THE UI SCALE IS A SIZE, NOT A ZOOM. It multiplies what the panel was placed
// at, so a suite taken down ten percent keeps every panel where its corner was
// and gives back the screen from the other two edges. Scaling the position too
// would pull the whole layout towards the top left, which is not what "make it
// smaller" means to anybody looking at it.
private _scale = [GVAR(uiScale), 1] select _fixed;
_pw = _pw * _scale;
_ph = _ph * _scale;

// Size first: a panel wider than the screen can never be clamped into it.
_pw = 0.05 max (_pw min 1);
_ph = 0.05 max (_ph min 1);
_px = 0 max (_px min (1 - _pw));
_py = 0 max (_py min (1 - _ph));

if (GVAR(respectZones) && HOST_NATIVE) then {
    {
        _x params ["_zx", "_zy", "_zw", "_zh"];

        private _hits = _px < (_zx + _zw) && {(_px + _pw) > _zx}
            && {_py < (_zy + _zh)} && {(_py + _ph) > _zy};

        if (_hits) then {
            // Four ways out. Keep the ones that still fit on screen, take the
            // one that moves the panel least, and leave it where it is if none
            // of them do - a panel nobody can place is worse than an overlap.
            private _options = [
                [_zx - _pw - PAD, _py],
                [_zx + _zw + PAD, _py],
                [_px, _zy - _ph - PAD],
                [_px, _zy + _zh + PAD]
            ] select {
                (_x # 0) >= 0 && {(_x # 0) <= (1 - _pw)} && {(_x # 1) >= 0} && {(_x # 1) <= (1 - _ph)}
            };

            // Nearest wins. Written as a plain minimum rather than a sort: it
            // is four candidates, and a sort algorithm block would have to
            // reach back out to _px and _py to measure against, which works
            // only because call sees the calling scope - a dependency that is
            // invisible at the point it would break.
            private _bestDist = 1e10;
            private _best = [];
            {
                _x params ["_ox", "_oy"];
                private _dist = abs (_ox - _px) + abs (_oy - _py);
                if (_dist < _bestDist) then {
                    _bestDist = _dist;
                    _best = [_ox, _oy];
                };
            } forEach _options;

            if (_best isNotEqualTo []) then {
                _px = _best # 0;
                _py = _best # 1;
            };
        };
    } forEach [ZONE_TOP, ZONE_MENU, ZONE_CHAT, ZONE_LEGEND];
};

[
    [
        HOST_X + _px * HOST_W,
        HOST_Y + _py * HOST_H,
        _pw * HOST_W,
        _ph * HOST_H
    ],
    [_px, _py, _pw, _ph]
]
