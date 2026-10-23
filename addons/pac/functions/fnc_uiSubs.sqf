#include "script_component.hpp"
/*
    File: fnc_uiSubs.sqf
    Author: YonV
    Description: The sub-tab row under a page title - the website's
        `.sections` / `.subrail` of links (ORBAT's Roles / Squads /
        Platoons..., a role's Identity / Nets / Tiles...). Up to eight; the
        one you are on is in the accent.

    Parameters:
        0: Tabs <ARRAY> - [[label, id], ...]
        1: The id that is on <STRING>
        2: What to do when one is clicked <CODE> - called with [id]

    Returns:
        Nothing
*/

params [["_tabs", [], [[]]], ["_on", "", [""]], ["_code", {}, [{}]]];

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};

private _idcs = [PAC_IDC_SUB1, PAC_IDC_SUB2, PAC_IDC_SUB3, PAC_IDC_SUB4, PAC_IDC_SUB5, PAC_IDC_SUB6, PAC_IDC_SUB7, PAC_IDC_SUB8];
private _n = (count _tabs) min 8;
private _gap = 0.004;
private _w = ((PAC_UI_W - (_n - 1) * _gap) / (_n max 1)) min 0.160;

{
    private _c = [_x] call FUNC(uiCtrl);
    if (_forEachIndex >= _n) then {
        _c ctrlShow false;
        _c setVariable [QGVAR(onClick), nil];
        continue;
    };
    (_tabs # _forEachIndex) params ["_label", "_id"];
    [_c, PAC_UI_X + _forEachIndex * (_w + _gap), 0.152, _w, 0.026] call FUNC(uiPlace);
    _c ctrlSetText _label;
    _c ctrlSetTextColor ([[0.545, 0.592, 0.639, 1], [0.576, 0.812, 0.447, 1]] select (_id isEqualTo _on));
    _c setVariable [QGVAR(id), _id];
    _c setVariable [QGVAR(code), _code];
    _c setVariable [QGVAR(onClick), {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(id), ""]] call (_ctrl getVariable [QGVAR(code), {}]);
    }];
} forEach _idcs;
