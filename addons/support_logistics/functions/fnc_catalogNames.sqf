#include "script_component.hpp"
/*
 * Author: YonV
 * Client: the names of the pre-made crates and items a RESUPPLY can ask for
 * (user, 2026-11-02: "we have pre made crates so the requested items should be
 * a drop down of them") - the source tacpad's composer asks for a RESUPPLY
 * item's picks (its choicesFrom "logiCatalog"). The catalog of each logistics
 * asset among the addressees given - its box "B:SUPPORT:logi:<n>" or its asset
 * id - or, with none of them there, of every logistics asset of the viewer's
 * side. Read off what the server published on each module (QGVAR(catalog)),
 * in catalog order, each name once.
 *
 * The server matches the picked name to the asset's catalog as before
 * (FUNC(catalogFind) in FUNC(srvThread)): a crate another asset carries is
 * CANTCO NO STORES <NAME>.
 *
 * Arguments:
 * 0: Addressees - box or asset ids <ARRAY of STRINGs>
 *
 * Return Value:
 * Item names, upper case <ARRAY of STRINGs>
 *
 * Example:
 * [["B:SUPPORT:logi:0"]] call jmfsb_support_logistics_fnc_catalogNames
 *
 * Public: Yes
 */

params [["_addressees", [], [[]]]];

if (!hasInterface) exitWith {[]};

private _side = side group player;
private _entities = (missionNamespace getVariable [QGVAR(entities), []]) select {
    !isNull _x && {(_x getVariable [QGVAR(side), sideUnknown]) isEqualTo _side}
};

// The logistics assets on TO, by their id inside the box.
private _picked = [];
private _stem = SUPPORT_KIND + ASSET_ID_SEP;
{
    if !(_x isEqualType "") then {continue};
    private _at = _x find _stem;
    if (_at < 0) then {continue};
    private _logic = [_x select [_at]] call FUNC(logicOf);
    if (isNull _logic) then {continue};
    if (_logic in _entities) then {_picked pushBackUnique _logic};
} forEach _addressees;
if (_picked isEqualTo []) then {_picked = _entities};

private _names = [];
{
    {
        private _name = _x param [ITEM_NAME, ""];
        if (_name isEqualType "" && _name isNotEqualTo "") then {_names pushBackUnique _name};
    } forEach (_x getVariable [QGVAR(catalog), []]);
} forEach _picked;

_names
