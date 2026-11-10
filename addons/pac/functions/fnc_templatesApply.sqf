#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_templatesApply

Description:
    Registers the report deck the structure carries - the "templates"
    section, one entry per template in the shape FUNC(registerTemplate)
    takes - with TAC//MSG, on this machine.

    THE MOD'S OWN CARD ALWAYS WINS (user, 2026-11-02: card changes reach
    the game with the mod - nobody runs a script against the database). A
    deck card whose id is already registered is skipped: a card the mod
    carries (jmfsb_messaging_fnc_builtinCards, jmfsb_support_fnc_builtinCards,
    FUNC(registerTemplates)) or one a mission that still ships
    JMFSBFR_Templates registered at preInit. A card the mod retired
    (jmfsb_messaging_retiredCards - accepted, ontask, nineline) is skipped
    too. The deck still adds every card the mod does not have - a unit's
    own cards. One RPT line names the deck cards skipped because the mod
    carries them, and the retired ones, when that list changes.

    Runs on the server after the structure is final (FUNC(boot)) and on a
    client whenever it takes the server's structure (FUNC(takeServer)), so
    the registry is the same everywhere before anyone composes.

Parameters:
    None

Returns:
    How many templates were registered <NUMBER>

Author:
    YonV
---------------------------------------------------------------------------- */

if (isNil "jmfsb_messaging_fnc_registerTemplate") exitWith {0};

private _deck = GVAR(structure) getOrDefault ["templates", createHashMap];
if !(_deck isEqualType createHashMap) exitWith {0};

private _have = missionNamespace getVariable ["jmfsb_messaging_templateIds", []];
private _retired = missionNamespace getVariable ["jmfsb_messaging_retiredCards", []];
private _made = 0;
private _carried = [];
private _dropped = [];
private _ids = keys _deck;
_ids sort true;
{
    if (_x in _retired) then {
        _dropped pushBack _x;
        continue;
    };
    if (_x in _have) then {
        if ((([_x] call jmfsb_messaging_fnc_template) getOrDefault ["builtin", false]) isEqualTo true) then {
            _carried pushBack _x;
        };
        continue;
    };
    private _t = _deck get _x;
    if !(_t isEqualType createHashMap) then {continue};
    private _lines = _t getOrDefault ["lines", []];
    private _options = _t getOrDefault ["options", []];
    if !(_lines isEqualType [] && _options isEqualType []) then {continue};
    if (([_x, _t getOrDefault ["title", _x], _t getOrDefault ["short", ""], _lines, _options] call jmfsb_messaging_fnc_registerTemplate) isNotEqualTo "") then {
        _made = _made + 1;
    };
} forEach _ids;

if (_made > 0) then {INFO_1("report deck from the structure: %1 template(s) registered",_made)};

// ONE LINE, and only when it changes: a client takes the structure on every
// publish, and the same list each time says nothing new.
private _skipped = [_carried, _dropped];
if (_skipped isNotEqualTo (localNamespace getVariable [QGVAR(deckSkipped), []]) && _skipped isNotEqualTo [[], []]) then {
    localNamespace setVariable [QGVAR(deckSkipped), _skipped];
    private _carriedText = ["none", _carried joinString ", "] select (_carried isNotEqualTo []);
    private _droppedText = ["none", _dropped joinString ", "] select (_dropped isNotEqualTo []);
    INFO_3("report deck: %1 card(s) skipped - the mod carries them: %2 - retired: %3",count _carried + count _dropped,_carriedText,_droppedText);
};
_made
