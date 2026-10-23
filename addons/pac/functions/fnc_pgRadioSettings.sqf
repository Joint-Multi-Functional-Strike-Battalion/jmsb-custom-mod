#include "script_component.hpp"
/*
    File: fnc_pgRadioSettings.sqf
    Author: YonV
    Description: The radio plan's settings - the website's "ACRE radios and
        power" form, and the net plan's fallback slots (game voice: nets,
        not frequencies - FUNC(netPlan)). SAVE writes the keys that changed.

    Parameters:
        None - reads GVAR(uiArgs): which ("acre" | "nets")

    Returns:
        Nothing
*/

private _which = GVAR(uiArgs) getOrDefault ["which", "acre"];
private _radio = GVAR(structure) getOrDefault ["radio", createHashMap];
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
private _fed = ["radio"] call FUNC(fileFed);
private _fnc_lines = {
    private _v = _radio getOrDefault [_this, []];
    if (_v isEqualType []) then {(_v apply {if (_x isEqualType "") then {_x} else {str _x}}) joinString (toString [10])} else {str _v}
};

[["ACRE radios and power", "Net plan fallbacks"] select (_which isEqualTo "nets"), format ["ORBAT  -  Communications  -  %1.radio%2", _unit, ["", "  -  from the config folder, read only in game"] select _fed]] call FUNC(uiTitle);

private _rows = if (_which isEqualTo "nets") then {[
    ["tfarSwFallback", "Short range fallback net slot  (0-8)", "n", _radio getOrDefault ["tfarSwFallback", 0]],
    ["tfarLrFallback", "Long range fallback net slot  (0-8)", "n", _radio getOrDefault ["tfarLrFallback", 0]]
]} else {[
    ["acreActiveRadio", "Radio in hand on spawn", "t", _radio getOrDefault ["acreActiveRadio", ""]],
    ["srPower", "SR power  (-1 = stock)", "n", _radio getOrDefault ["srPower", -1]],
    ["mrPower", "MR power", "n", _radio getOrDefault ["mrPower", -1]],
    ["lrPower", "LR power", "n", _radio getOrDefault ["lrPower", -1]],
    ["srFallback", "SR fallback channel", "n", _radio getOrDefault ["srFallback", 1]],
    ["mrDefault", "MR default channel", "n", _radio getOrDefault ["mrDefault", 1]],
    ["lrDefault", "LR default channel", "n", _radio getOrDefault ["lrDefault", 1]],
    ["lrSatChannel", "LR sat channel", "n", _radio getOrDefault ["lrSatChannel", 1]],
    ["lrLocalChannel", "LR local channel", "n", _radio getOrDefault ["lrLocalChannel", 1]],
    ["srRadios", "Short range radios  (one per line)", "m", "srRadios" call _fnc_lines, 2],
    ["mrRadios", "Medium range radios", "m", "mrRadios" call _fnc_lines, 2],
    ["lrRadios", "Long range radios", "m", "lrRadios" call _fnc_lines, 2],
    ["acreNoProgram", "Never programmed", "m", "acreNoProgram" call _fnc_lines, 2]
]};
[_rows, PAC_UI_TOP] call FUNC(uiForm);

if (_fed) exitWith {[[]] call FUNC(uiButtons)};
[[
    ["SAVE", {
        private _f = [] call FUNC(uiFormRead);
        private _radio = GVAR(structure) getOrDefault ["radio", createHashMap];
        private _n = 0;
        {
            _x params ["_key", "_kind"];
            private _v = _f get _key;
            if (_kind isEqualTo "m") then {_v = ((_v splitString (toString [10])) apply {trim _x}) select {_x isNotEqualTo ""}};
            if (_v isEqualType "") then {_v = trim _v};
            // a key the plan does not hold yet is always sent - the sentinel never equals a value
            private _was = _radio getOrDefault [_key, ["__unset__"]];
            if (_v isNotEqualTo _was) then {
                [player, "radio", "set", _key, createHashMapFromArray [["value", _v]]] remoteExec [QFUNC(adminOrbat), 2];
                _n = _n + 1;
            };
        } forEach GVAR(uiFormKeys);
        [[format ["%1 setting(s) sent.", _n], "Nothing changed."] select (_n isEqualTo 0), false] call FUNC(uiHint);
    }]
]] call FUNC(uiButtons);
