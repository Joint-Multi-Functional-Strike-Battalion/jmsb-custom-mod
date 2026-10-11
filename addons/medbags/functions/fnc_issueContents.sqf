#include "..\script_component.hpp"
/*
 * Author: YonV
 * Issues one bag's worth of kit to a unit, from a "class:count" settings list.
 *
 * WHAT THIS REPLACED. Every fnc_doUnpack* ended in a column of hardcoded
 * EFUNC(common,addItem) calls - thirteen of them in the Medic Bag - each with
 * its own copy of a private _order and a private _overflow that were the same
 * numbers every time. Changing what a bag holds meant editing SQF and shipping
 * a new PBO. The lists are settings now (see initSettings.inc.sqf) and this is
 * the one place that reads them.
 *
 * ORDER IS KEPT, DUPLICATES INCLUDED. The list is issued top to bottom, and a
 * man fills up: what is early in the list is what he keeps. A class named twice
 * is issued twice, because the second helping lands in a different container
 * once the first has filled the near one.
 *
 * A CLASS NOTHING DEFINES IS SKIPPED. EFUNC(common,addItem) does not check that
 * an item exists - canAddItemToUniform is false for a classname that was never
 * defined, so the item falls through to the overflow branch, which builds a
 * GroundWeaponHolder, puts nothing in it and leaves it standing there. That is
 * how "JMFSB_Apap" behaved in here: a painkiller jmfsb defines and DIVINER does
 * not, issued by three bags, arriving as nothing. It is out of the defaults, and
 * anything else that goes the same way now says so in the RPT instead.
 *
 * SCHEDULED ONLY. It sleeps between items, as the unpack always did. Call it
 * from the spawn in a fnc_doUnpack*, not from unscheduled code.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Contents, "class:count" comma separated <STRING>
 *
 * Return Value:
 * How many entries were issued <NUMBER>
 *
 * Example:
 * [_unit, GVAR(contentsFirstAid)] call jmfsb_medbags_fnc_issueContents;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_contents", "", [""]]];

if (isNull _unit) exitWith {0};

// The container codes EFUNC(common,addItem) switches on: 1 uniform, 2 vest, 3
// backpack.
// A setting that has been edited into nonsense falls back to the default rather
// than handing addItem an empty priority list.
private _order = (GVAR(fillOrder) splitString ",") apply {parseNumber (trim _x)} select {_x in [1, 2, 3]};
if (_order isEqualTo []) then {
    WARNING_1("fillOrder '%1' names no container - using backpack, vest, uniform",GVAR(fillOrder));
    _order = [3, 2, 1];
};

private _overflow = GVAR(fillOverflow);
private _issued = 0;

{
    private _entry = _x;
    private _pair = _entry splitString ":";

    if (count _pair < 2) then {
        WARNING_1("medbag contents entry '%1' is not class:count - skipped",_entry);
    } else {
        private _item = trim (_pair select 0);
        private _count = parseNumber (trim (_pair select 1));

        switch (true) do {
            case (_count < 1): {
                WARNING_2("medbag contents entry '%1' asks for %2 - skipped",_entry,_count);
            };
            // CfgMagazines as well as CfgWeapons: ACE issues some of its
            // medical kit as one and some as the other, and addItem takes both.
            // CfgGlasses too - the MOPP bag's respirator is facewear.
            case (
                !isClass (configFile >> "CfgWeapons" >> _item) &&
                {!isClass (configFile >> "CfgMagazines" >> _item)} &&
                {!isClass (configFile >> "CfgGlasses" >> _item)}
            ): {
                WARNING_1("medbag contents names '%1', which no loaded mod defines - skipped",_item);
            };
            default {
                [_unit, _item, _count, _order, _overflow] call EFUNC(common,addItem);
                _issued = _issued + 1;
                sleep 0.3;
            };
        };
    };
} forEach ((_contents splitString ",") apply {trim _x} select {_x isNotEqualTo ""});

_issued
