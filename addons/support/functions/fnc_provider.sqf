#include "script_component.hpp"
/*
 * Author: JMSB
 * The provider that owns an asset id - the id's prefix up to the first ":".
 *
 * Arguments:
 * 0: Asset id <STRING>
 *
 * Return Value:
 * 0: Kind, "" when the id names no registered provider <STRING>
 * 1: Declaration, empty when none <HASHMAP>
 *
 * Example:
 * ["cas:0"] call jmfsb_support_fnc_provider
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _kind = (_assetId splitString ID_SEP) param [0, ""];
private _decl = GVAR(providers) getOrDefault [_kind, createHashMap];

[[_kind, ""] select (count _decl == 0), _decl]
