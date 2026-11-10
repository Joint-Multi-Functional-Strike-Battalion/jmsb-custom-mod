#include "script_component.hpp"
/*
 * Author: YonV
 * Makes a string safe to put inside a structured-text tag.
 *
 * parseText is XML. An ampersand starts an entity, so "NETS & ALERTS" is not a
 * label with an ampersand in it - it is a label followed by an entity called
 * " ALERTS" that does not exist, and the engine says so once per frame.
 *
 * This is not a theoretical hazard: a message subject is whatever the sender
 * typed, and the reader draws it. Anything that reaches parseText through the
 * drawing vocabulary goes through here first.
 *
 * The ampersand is replaced FIRST, or the ampersands in the replacements
 * themselves would be escaped a second time and print as &amp;lt;.
 *
 * Arguments:
 * 0: Text <STRING>
 *
 * Return Value:
 * Text with &, < and > escaped <STRING>
 *
 * Example:
 * private _safe = ["NETS & ALERTS"] call jmfsb_tacpad_fnc_xmlSafe
 *
 * Public: Yes
 */

params [["_text", "", [""]]];

if (_text == "") exitWith {""};

_text = _text regexReplace ["&", "&amp;"];
_text = _text regexReplace ["<", "&lt;"];
_text regexReplace [">", "&gt;"]
