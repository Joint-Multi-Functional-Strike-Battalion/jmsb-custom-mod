#include "script_component.hpp"
/*
 * Author: YonV
 * What the marker card offers, read from the game's config once a mission and
 * kept (user, 2026-11-02: "need more map markers in the map marker solution" -
 * "and all that are in this mod").
 *
 * THE ICONS: every CfgMarkers class with scope above 0 and an icon, sorted into
 * the tabs of CARD_CATEGORIES by class prefix - hd_ BASIC, mil_ MIL, b_ / o_ /
 * n_ the NATO sides, c_ / u_ / loc_ CIVIL, flag_ FLAGS. Scope 1 counts: the
 * base game gives the NATO symbols, the flags and the places scope 1, and this
 * mod gives hd_ scope 1 (jmfsb_map). What no prefix takes - the system
 * markers, group sizes, respawn and selection marks - is left out.
 *
 * THIS MOD'S OWN: a class every source addon of which is one of this mod's
 * (configSourceAddonList, "jmfsb_...") goes under CARD_CATEGORY_MOD whatever
 * its name - so a jmfsb marker added later is there without a list. A base-game
 * class this mod only re-scopes (hd_dot, mil_objective) has the game's addon
 * among its sources and stays in its own tab.
 *
 * Each tab: CARD_TYPES_LEAD's marks first, in that order, then CfgMarkers'
 * order. A tab with nothing in it is not offered.
 *
 * THE COLOURS: every CfgMarkerColors class with scope above 0 and a four-part
 * colour, in config order - Default (the marker's own colour) first.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [tabs, colours] <ARRAY>
 *   tabs: [id, label, tooltip, own colours, [[class, icon, name], ...]] each
 *   colours: [class, name, RGBA] each
 *
 * Example:
 * ([] call jmfsb_maptools_fnc_markerCardCatalog) params ["_tabs", "_colours"]
 *
 * Public: No
 */

if (!isNil QGVAR(cardCatalog)) exitWith {GVAR(cardCatalog)};

private _table = CARD_CATEGORIES;
private _lead = CARD_TYPES_LEAD;
private _modPrefix = toLowerANSI (QUOTE(PREFIX) + "_");
private _found = createHashMap;
{
    _found set [_x # 0, []];
} forEach _table;

{
    private _class = configName _x;
    private _icon = getText (_x >> "icon");
    if (getNumber (_x >> "scope") < 1 || _icon isEqualTo "") then {continue};

    private _sources = configSourceAddonList _x;
    private _ours = _sources isNotEqualTo [];
    if (_ours) then {
        _ours = (_sources findIf {(toLowerANSI _x) find _modPrefix != 0}) < 0;
    };

    private _tab = CARD_CATEGORY_MOD;
    if (!_ours) then {
        private _lower = toLowerANSI _class;
        private _at = _table findIf {((_x # 3) findIf {_lower find (toLowerANSI _x) == 0}) > -1};
        _tab = if (_at < 0) then {""} else {(_table # _at) # 0};
    };
    if (_tab isEqualTo "") then {continue};

    // Sorted on [lead rank, config order]: a lead mark by its place in the
    // lead list, the rest after it in the order the config has them.
    private _rank = _lead find _class;
    if (_rank < 0) then {
        _rank = count _lead;
    };
    (_found get _tab) pushBack [_rank, _forEachIndex, _class, _icon, getText (_x >> "name")];
} forEach ("true" configClasses (configFile >> "CfgMarkers"));

private _tabs = [];
{
    _x params ["_id", "_label", "_tip", "", "_own"];
    private _types = _found get _id;
    if (_types isEqualTo []) then {continue};
    _types sort true;
    _tabs pushBack [_id, _label, _tip, _own, _types apply {[_x # 2, _x # 3, _x # 4]}];
} forEach _table;

private _colours = [];
{
    if (getNumber (_x >> "scope") < 1 || count getArray (_x >> "color") != 4) then {continue};
    _colours pushBack [configName _x, getText (_x >> "name"), (_x >> "color") call BIS_fnc_colorConfigToRGBA];
} forEach ("true" configClasses (configFile >> "CfgMarkerColors"));

GVAR(cardCatalog) = [_tabs, _colours];
GVAR(cardCatalog)
