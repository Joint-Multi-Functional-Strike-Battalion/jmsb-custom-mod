#include "script_component.hpp"
/*
 * Author: YonV
 * One JMSB - Logistics Catalog module: reads its objects into a catalog on
 * the server (FUNC(catalogRead)) at the start, whether or not a logistics
 * module has asked for it yet - so "Remove The Objects" happens at the
 * start either way. A logistics module that reads it later gets the same
 * list back.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, [], true] call jmfsb_support_logistics_fnc_moduleCatalog
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic} || {!isServer}) exitWith {};

[_logic] call FUNC(catalogRead);
