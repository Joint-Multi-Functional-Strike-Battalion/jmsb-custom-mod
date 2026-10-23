#include "script_component.hpp"
/*
    File: fnc_pgDoc.sqf
    Author: YonV
    Description: One Mongo document - the website's ?page=document: the
        JSON in a box, SAVE writes it back as it stands. The store document
        asks twice, as the website does with its checkbox.

    Parameters:
        None - reads GVAR(uiArgs): key

    Returns:
        Nothing
*/

private _key = GVAR(uiArgs) getOrDefault ["key", ""];
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
["Mongo doc", _key + (["", "  -  THIS IS THE STORE: players, sessions, windows, the log. Replacing it replaces the roster."] select (_key isEqualTo _unit))] call FUNC(uiTitle);
if !(["doc:" + _key] call FUNC(uiAsk)) exitWith {};

private _json = GVAR(uiData) getOrDefault ["doc:" + _key, ""];
if !(_json isEqualType "") then {_json = ""};

disableSerialization;
private _head = [PAC_IDC_BIGEDIT_HEAD, PAC_UI_X, PAC_UI_TOP, PAC_UI_W, 0.026] call FUNC(uiPlace);
_head ctrlSetStructuredText parseText format ["<t color='#93cf72' size='0.7'>JSON  %1 characters</t>", count _json];
private _edit = [PAC_IDC_BIGEDIT, PAC_UI_X, PAC_UI_TOP + 0.028, PAC_UI_W, PAC_UI_BOTTOM - PAC_UI_TOP - 0.028] call FUNC(uiPlace);
_edit ctrlSetText _json;

[[
    ["SAVE", {
        disableSerialization;
        private _key = GVAR(uiArgs) getOrDefault ["key", ""];
        private _text = ctrlText ([PAC_IDC_BIGEDIT] call FUNC(uiCtrl));
        ([_text] call FUNC(fromJson)) params ["", "_ok", "_where"];
        if (!_ok) exitWith {[format ["That is not JSON (error at %1).", _where], true] call FUNC(uiHint)};
        [format ["Write %1 back to the database as it stands?%2", _key, ["", " THIS REPLACES THE STORE DOCUMENT."] select (_key isEqualTo (GVAR(settings) getOrDefault ["unitId", ""]))], {
            params ["_key", "_text"];
            [player, _key, _text] remoteExec [QFUNC(adminDoc), 2];
            GVAR(uiData) deleteAt ("doc:" + _key);
            ["Written - the next boot reads it.", false] call FUNC(uiHint);
        }, [_key, _text]] call FUNC(uiConfirm);
    }],
    ["RELOAD", {GVAR(uiData) deleteAt ("doc:" + (GVAR(uiArgs) getOrDefault ["key", ""])); [] call FUNC(uiDraw)}]
]] call FUNC(uiButtons);
