#include "script_component.hpp"
/*
 * Author: YonV
 * Compiles and calls a user hook (an SQF code string from a CBA setting) with
 * the given arguments. No-op if the string is empty.
 *
 * Arguments:
 * 0: SQF code string <STRING>
 * 1: Arguments passed to the code as _this <ANY>
 *
 * Return Value:
 * Whatever the hook returns (nil if empty) <ANY>
 *
 * Public: No
 */

params [["_code", "", [""]], ["_args", []]];
if (_code isEqualTo "") exitWith {};

_args call (compile _code)
