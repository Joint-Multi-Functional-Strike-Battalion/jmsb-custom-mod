#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts a handheld in his hand: the first TFAR instance he carries of the
 * named arsenal class (its tf_parent) becomes TFAR's active short range radio
 * - the TFAR path of jmfsb_players_fnc_setActiveRadio, with the PAC plan's
 * tfarActiveRadio. Waits a second for TFAR to have swapped the prototypes for
 * numbered instances. Nothing happens when he carries none of that class.
 *
 * (The 1268 TFAR branch skipped the named class and activated the first
 * other one; this follows the ACRE branch's meaning, "this radio is active".)
 *
 * Arguments:
 * 0: Arsenal radio class, "" to leave TFAR's choice <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["jmfsb_mpu5"] call jmfsb_adapter_tfar_fnc_activeRadio
 *
 * Public: Yes
 */

params [["_class", "", [""]]];

if (!hasInterface || _class isEqualTo "" || {isNil "TFAR_fnc_getRadioItems"}) exitWith {};

[{
    params ["_class"];
    private _items = [player] call TFAR_fnc_getRadioItems;
    private _at = _items findIf {
        private _parent = getText (configFile >> "CfgWeapons" >> _x >> "tf_parent");
        _parent isEqualTo _class && _x isNotEqualTo _parent
    };
    if (_at < 0) exitWith {WARNING_2("%1 carries no %2 to put in hand",player,_class)};
    [_items select _at] call TFAR_fnc_setActiveSwRadio;
    [[], -1] call FUNC(poll);
    INFO_2("%1 has %2 in hand",player,call TFAR_fnc_activeSwRadio);
}, [_class], 1] call CBA_fnc_waitAndExecute;
