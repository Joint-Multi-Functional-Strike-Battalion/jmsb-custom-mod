#include "script_component.hpp"
/*
 * Author: YonV
 * A comma-separated setting as a list of class names, trimmed, blanks dropped.
 *
 * Arguments:
 * 0: The setting's text <STRING>
 *
 * Return Value:
 * Class names <ARRAY>
 *
 * Example:
 * [jmfsb_jumpmaster_chuteClasses] call jmfsb_jumpmaster_fnc_classList
 *
 * Public: No
 */

params [["_text", "", [""]]];

((_text splitString ",") apply {trim _x}) select {_x isNotEqualTo ""}
