#include "script_component.hpp"
/*
 * Author: YonV
 * The net chips of the page the net rows show - the walking view's bottom
 * row and the tablet's (docs/DESIGN_VOICE.md, "Nets on the devices"). The
 * nets are FUNC(netEntries)' (only nets the player is on, a net he cannot
 * reach drawn red, never hidden, the ear tag, receive only, a RING cell for
 * a ringing call), put on the twelve net buttons by FUNC(netButtons); this
 * answers the four of the page shown.
 *
 * NUMBERED BY PAGE. A chip reads "<N> <NAME>": N is its place on the page and
 * the SELECT NET N key (FUNC(netSelect); numpad 1-4 by default) - whatever
 * page is shown, numpad 1 is its first chip.
 *
 * NEVER A FREQUENCY. A net is a name.
 *
 * Arguments:
 * 0: FUNC(netButtons)' answer, when the caller already has it <ARRAY>
 *    (optional, default: asked here)
 *
 * Return Value:
 * NET_PAGE_SIZE entries, one per cell of the page shown: [number (1-based),
 * label, active, net id, reachable, ear, muted, kind, quality 0-1,
 * transmitting, receive only] - kind "ring" for the ringing cell - or [] for
 * an empty cell; [] when he is on no net, or without the voice addon <ARRAY>
 *
 * Example:
 * private _nets = [] call jmfsb_devices_fnc_overlayNets
 *
 * Public: Yes
 */

params [["_state", [], [[]]]];

if (_state isEqualTo []) then {_state = [] call FUNC(netButtons)};
_state params [["_buttons", [], [[]]], ["_page", 0, [0]]];

private _shown = _buttons select [_page * NET_PAGE_SIZE, NET_PAGE_SIZE];
if ((_shown findIf {_x isNotEqualTo []}) < 0) exitWith {[]};

private _out = [];
{
    if (_x isEqualTo []) then {
        _out pushBack [];
        continue;
    };
    private _entry = +_x;
    // the F-row layout numbers the buttons 1-8 straight, its Shift + F keys
    // (FUNC(netChip)); the numpad layout by place on the page
    private _number = _forEachIndex + 1 + ([0, _page * NET_PAGE_SIZE] select ([] call FUNC(keyOwned)));
    _entry set [0, _number];
    _entry set [1, format ["%1 %2", _number, _x select 1]];
    _out pushBack _entry;
} forEach _shown;

_out
