#include "script_component.hpp"
/*
 * Author: YonV
 * Registers a panel with the shell. A panel is a title, a default place on the
 * screen, a builder that fills its body, and a setting that says whether the
 * player wants it - the shell owns the frame, the placement and the theming,
 * so a panel never has to know about any of that.
 *
 * Call it in preInit. The shell builds nothing until the map opens.
 *
 * Arguments:
 * 0: Panel id, lowercase <STRING>
 * 1: Header title <STRING>
 * 2: Default place [x, y, w, h] in safe-zone fractions <ARRAY>
 * 3: Builder, called with [body control, panel id] each time the map opens <CODE>
 * 4: Refresher, called with the same while the map is open, {} for none <CODE> (optional, default {})
 * 5: Seconds between refreshes <NUMBER> (optional, default 2)
 * 6: Draw a title bar <BOOL> (optional, default true)
 * 7: Condition for the panel existing at all, checked each time the map opens <CODE> (optional, default {true})
 *
 * Return Value:
 * Registered <BOOL> - false when every slot is taken
 *
 * A CHROMELESS PANEL IS A BUTTON, not a window. No header, no title, no rule -
 * the frame is an outline and the body fills it. The three strips under the
 * reader are registered this way: a title bar reading SETTINGS over a cell
 * reading SETTINGS is the same word twice, and on a control that short the bar
 * was half its height.
 *
 * THE CONDITION IS FOR PANELS THAT SHOULD NOT EXIST FOR EVERYONE. Distinct from
 * the player's own show/hide setting, which is a preference - this is whether
 * the panel is theirs to have at all. Checked on every map open, so a promotion
 * mid-mission is one map close away from taking effect.
 *
 * Example:
 * ["squad", "SQUAD", DEFAULT_SQUAD, FUNC(panelSquad)] call jmfsb_tacpad_fnc_register
 *
 * Public: Yes
 */

params [
    ["_id", "", [""]],
    ["_title", "", [""]],
    ["_default", [0.1, 0.1, 0.2, 0.2], [[]], 4],
    ["_builder", {}, [{}]],
    ["_refresher", {}, [{}]],
    ["_period", 2, [0]],
    ["_chrome", true, [false]],
    ["_condition", {true}, [{}]]
];

if (_id == "") exitWith {false};

// The slot is what gives a panel its IDC block, so it has to be stable for the
// life of the mission - a panel keeps the slot it first claimed even if it is
// re-registered by a recompile.
private _order = GVAR(order);
if !(_id in _order) then {
    if (count _order < PANEL_MAX) then {
        _order pushBack _id;
    };
};

if !(_id in _order) exitWith {
    ERROR_2("panel '%1' rejected - all %2 slots are taken",_id,PANEL_MAX);
    false
};

GVAR(panels) set [_id, createHashMapFromArray [
    ["id", _id],
    ["title", _title],
    ["default", _default],
    ["builder", _builder],
    ["refresher", _refresher],
    ["period", _period],
    ["chrome", _chrome],
    ["condition", _condition],
    ["slot", _order find _id]
]];

true
