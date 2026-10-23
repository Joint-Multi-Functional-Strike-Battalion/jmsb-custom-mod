#include "script_component.hpp"
/*
 * Author: JMSB
 * The RF profile a radio item or radio bag carries: the class's own
 * jmfsb_rf_profile config property (CfgWeapons first, then CfgVehicles for a
 * backpack). An item in the radio slot (simulation ItemRadio) with no property
 * is a handheld; anything else without one is not a radio set. A profile RF
 * does not know (RF_PROFILES) is not a set either. Cached per class - config
 * does not change in a mission.
 *
 * This is how RF recognises a carried set with no radio mod loaded: the item
 * says what it is, RF never keeps a list of class names.
 *
 * Arguments:
 * 0: Item or backpack class <STRING>
 *
 * Return Value:
 * Profile id, "" when the class is not a radio set <STRING>
 *
 * Example:
 * ["jmfsb_mpu5"] call jmfsb_rf_fnc_itemProfile // "handheld"
 *
 * Public: Yes
 */

params [["_class", "", [""]]];

if (_class isEqualTo "") exitWith {""};

private _cached = GVAR(itemProfiles) get _class;
if (!isNil "_cached") exitWith {_cached};

private _cfg = configFile >> "CfgWeapons" >> _class;
private _isItem = isClass _cfg;
if (!_isItem) then {_cfg = configFile >> "CfgVehicles" >> _class};

private _profile = getText (_cfg >> QGVAR(profile));
if (_profile isEqualTo "" && _isItem && {getText (_cfg >> "simulation") == RADIO_ITEM_SIMULATION}) then {
    _profile = RADIO_ITEM_DEFAULT_PROFILE;
};
if !(_profile in GVAR(profiles)) then {_profile = ""};

GVAR(itemProfiles) set [_class, _profile];
_profile
