#include "script_component.hpp"
/*
 * Author: YonV
 * The quick brief the mission loading screen shows: the current OPORD's
 * quickBrief from the mission's CfgGFA_PAC (TAC//PAC's structure - the OPORD
 * that settings >> currentOpord names), or the mission's overviewText when
 * there is no CfgGFA_PAC, no current OPORD or no quickBrief on it.
 *
 * Read straight off missionConfigFile, which is there while the mission
 * loads; nothing of TAC//PAC's has run at that point, so the compiled
 * structure (and a database-held OPORD) cannot be asked. Runs in the UI
 * context, from the loading display's load handler.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * 0: Subtitle - the OPORD's title (its id when it has none), or the overview label <STRING>
 * 1: Brief text, structured text markup allowed, "" when there is nothing to show <STRING>
 *
 * Example:
 * [] call jmfsb_loading_fnc_quickBrief
 *
 * Public: No
 */

private _pac = missionConfigFile >> "CfgGFA_PAC";
private _opordId = getText (_pac >> "settings" >> "currentOpord");

private _subtitle = "";
private _text = "";
if (_opordId isNotEqualTo "") then {
    private _opord = _pac >> "opords" >> _opordId;
    _text = getText (_opord >> "quickBrief");
    _subtitle = getText (_opord >> "header" >> "title");
    if (_subtitle isEqualTo "") then {_subtitle = _opordId};
};

if (_text isEqualTo "") then {
    _subtitle = BRIEF_OVERVIEW_SUBTITLE;
    _text = getText (missionConfigFile >> "overviewText");
};

// $STR_ keys resolve, as the engine resolves its own loading text
_text = _text call (uiNamespace getVariable ["BIS_fnc_localize", {_this}]);
_subtitle = _subtitle call (uiNamespace getVariable ["BIS_fnc_localize", {_this}]);

[_subtitle, _text]
