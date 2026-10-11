#include "..\script_component.hpp"
/*
 * Author: YonV
 * Whether a unit can unpack a MOPP bag - any of the three camos.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Can unpack <BOOL>
 *
 * Example:
 * [player] call jmfsb_medbags_fnc_canUnpackMopp
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {false};

private _items = items _unit;

(
    ([QGVAR(Mopp_MTP), QGVAR(Mopp_Tropic), QGVAR(Mopp_Wdl)] findIf {_x in _items}) > -1 &&
    {alive _unit} &&
    {!(_unit getVariable ["ace_captives_isSurrendering", false])} &&
    {!(_unit getVariable ["ace_captives_isHandcuffed", false])} &&
    {!(_unit getVariable ["ace_isUnconscious", false])} &&
    {!visibleMap}
)
