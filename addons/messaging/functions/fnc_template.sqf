#include "script_component.hpp"
/*
 * Author: YonV
 * Looks a template up by id.
 *
 * Arguments:
 * 0: Template id <STRING>
 *
 * Return Value:
 * Template <HASHMAP>, or an empty HashMap when there is no such template.
 * Callers test with isEqualTo createHashMap rather than isNil, so a missing
 * template reads as "no fields" everywhere instead of throwing.
 *
 * Example:
 * private _t = ["sitrep"] call jmfsb_messaging_fnc_template
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

GVAR(templates) getOrDefault [_id, createHashMap]
