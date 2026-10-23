#include "script_component.hpp"
/*
 * Author: JMSB
 * A fresh net key: a random hex string. Keys are compared, never decoded;
 * holding the same key is what lets two sets decode each other.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Key <STRING>
 *
 * Example:
 * private _key = [] call jmfsb_rf_fnc_newKey
 *
 * Public: Yes
 */

private _chars = KEY_CHARS;
private _n = count _chars;
private _key = "";
for "_i" from 1 to KEY_LENGTH do {
    _key = _key + (_chars select [floor random _n, 1]);
};
_key
