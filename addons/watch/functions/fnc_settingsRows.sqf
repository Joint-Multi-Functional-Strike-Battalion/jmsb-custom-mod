#include "script_component.hpp"
/*
 * Author: YonV
 * The watch HUD's section of the tablet's SETTINGS app (design settings_app),
 * registered with jmfsb_tacpad_apps' settings sections and drawn by it:
 *
 *     prompt mode, shrink at distance, auto-clear, self aid, squad view time
 *                         the player's CBA settings, through CBA's own setter
 *                         (a server-forced one is drawn locked)
 *     the slot list       each watched slot - press: pin / unpin, < : clear
 *     add from squad      a squad member, without looking at him - into the
 *                         first profile that takes him
 *     the action key      as bound
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Rows, each [label, value, action, down action, locked, [down glyph, up glyph]] <ARRAY>
 *
 * Example:
 * [] call jmfsb_watch_fnc_settingsRows
 *
 * Public: No
 */

private _reopen = {[{["settings"] call EFUNC(tacpad,openApp)}] call CBA_fnc_execNextFrame};
private _fnc_toggle = {
    params ["_label", "_setting"];
    private _on = missionNamespace getVariable [_setting, false];
    [_label, ["OFF", "ON"] select _on,
        compile format ["[%1, %2] call %3", str _setting, !_on, QEFUNC(tacpad_apps,setSetting)], {},
        [_setting] call EFUNC(tacpad_apps,settingLocked)]
};

private _rows = [];
_rows pushBack ["PROMPT MODE", toUpper GVAR(prompt),
    compile format ["[%1, %2, 1] call %3", str QGVAR(prompt), str ["full", "reduced"], QEFUNC(tacpad_apps,settingCycle)],
    compile format ["[%1, %2, -1] call %3", str QGVAR(prompt), str ["full", "reduced"], QEFUNC(tacpad_apps,settingCycle)],
    [QGVAR(prompt)] call EFUNC(tacpad_apps,settingLocked), ["<", ">"]];
_rows pushBack (["SHRINK AT DISTANCE", QGVAR(shrink)] call _fnc_toggle);
_rows pushBack (["AUTO-CLEAR", QGVAR(autoClear)] call _fnc_toggle);
_rows pushBack (["SELF AID", QGVAR(selfAid)] call _fnc_toggle);
_rows pushBack (["HUD: MEDICAL", QGVAR(hud_medical)] call _fnc_toggle);
_rows pushBack (["HUD: TEAM LEAD", QGVAR(hud_team_lead)] call _fnc_toggle);
_rows pushBack (["HUD: ENGINEER", QGVAR(hud_engineer)] call _fnc_toggle);
_rows pushBack (["HUD: RECON CONTACTS", QGVAR(hud_recon)] call _fnc_toggle);
_rows pushBack (["HUD: JFO IMPACT AREAS", QGVAR(hud_jfo)] call _fnc_toggle);
_rows pushBack ["SQUAD VIEW TIME", format ["%1 S", round GVAR(squadViewSeconds)],
    compile format ["[%1, 5, 5, 120, 0] call %2", str QGVAR(squadViewSeconds), QEFUNC(tacpad_apps,settingStep)],
    compile format ["[%1, -5, 5, 120, 0] call %2", str QGVAR(squadViewSeconds), QEFUNC(tacpad_apps,settingStep)],
    [QGVAR(squadViewSeconds)] call EFUNC(tacpad_apps,settingLocked)];

// the slot list: press to pin or unpin, < to clear
{
    private _id = _x;
    private _spec = GVAR(profiles) getOrDefault [_id, createHashMap];
    private _row = _spec getOrDefault ["row", {[]}];
    {
        _x params ["_target", "_pinned"];
        if (isNull _target) then {continue};
        GVAR(settingsSlots) set [format ["%1|%2", _id, _forEachIndex], [_id, _target]];
        private _key = format ["%1|%2", _id, _forEachIndex];
        _rows pushBack [
            format ["%1 %2  %3", toUpper (_spec getOrDefault ["name", _id]), _forEachIndex + 1, ([_target] call _row) param [0, name _target]],
            ["PIN", "PINNED"] select _pinned,
            compile format ["(%1 getOrDefault [%2, []]) params ['_id', '_t']; private _s = (%3 getOrDefault [_id, []]) select {(_x # 0) isEqualTo _t}; if (_s isNotEqualTo []) then {(_s # 0) set [1, !((_s # 0) # 1)]}; %4",
                QGVAR(settingsSlots), str _key, QGVAR(slots), _reopen],
            compile format ["(%1 getOrDefault [%2, []]) params ['_id', '_t']; [_id, _t] call %3; %4", QGVAR(settingsSlots), str _key, QFUNC(toggle), _reopen],
            false, ["CLEAR", "PIN"]
        ];
    } forEach _y;
} forEach GVAR(slots);

// add from the squad, without looking
{
    private _man = _x;
    if (_man isEqualTo player || {(values GVAR(slots)) findIf {(_x findIf {(_x # 0) isEqualTo _man}) >= 0} >= 0}) then {continue};
    private _id = [_man] call FUNC(profileFor);
    if (_id isEqualTo "") then {continue};
    private _key = format ["add|%1", _forEachIndex];
    GVAR(settingsSlots) set [_key, [_id, _man]];
    _rows pushBack [format ["ADD %1", toUpper name _man], toUpper ((GVAR(profiles) get _id) getOrDefault ["name", _id]),
        compile format ["(%1 getOrDefault [%2, []]) params ['_id', '_t']; [_id, _t] call %3; %4", QGVAR(settingsSlots), str _key, QFUNC(toggle), _reopen],
        {}, false];
} forEach (units group player);

// the action key, as bound
private _bind = [JMFSB_CATEGORY, QGVAR(action)] call CBA_fnc_getKeybind;
private _label = "UNBOUND";
if (!isNil "_bind") then {
    (_bind param [5, [0, []]]) params [["_dik", 0, [0]]];
    if (_dik > 1) then {_label = toUpper (((keyName _dik) splitString """") joinString "")};
};
_rows pushBack ["ACTION KEY (ADD / REMOVE)", _label, {}, {}, false];
_rows
