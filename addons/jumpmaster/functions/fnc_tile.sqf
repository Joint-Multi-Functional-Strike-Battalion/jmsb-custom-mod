#include "script_component.hpp"
/*
 * Author: JMSB
 * The JUMPMASTER tile for jmfsb_tacpad_apps' band (a provider registered in
 * XEH_preInit). A squad leader's or an admin's only: anyone else gets no
 * tile, and so no way into the page. The run's phase while one is up; else
 * the plan's type and whether the stick is ready.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Tile entries, [] or one [appId, kicker, qualifier, value, detail, state] <ARRAY>
 *
 * Example:
 * [] call jmfsb_jumpmaster_fnc_tile
 *
 * Public: No
 */

if !([] call FUNC(isJumpmaster)) exitWith {[]};

private _run = (call CBA_fnc_currentUnit) getVariable [QGVAR(run), []];
if (_run isNotEqualTo []) exitWith {
    _run params ["_phase", "_pass", "_passes"];
    private _word = (PHASE_WORDS select {(_x select 0) isEqualTo _phase}) param [0, ["", "RUN"]] select 1;
    [[APP_ID, APP_TITLE, GVAR(type), _word, format ["PASS %1 OF %2", _pass, _passes], ["rest", "alert"] select (_phase isEqualTo PHASE_GREEN)]]
};

([GVAR(type)] call FUNC(ready)) params ["_rows", "_ready", "_missing"];
private _path = GVAR(red) isNotEqualTo [] && {GVAR(green) isNotEqualTo []};
[[
    APP_ID, APP_TITLE, GVAR(type),
    format ["%1 M", [GVAR(type)] call FUNC(typeAlt)],
    switch (true) do {
        case (!_path): {"NO FLIGHT PATH - PRESS TO PLAN"};
        case (!_ready): {format ["%1 NOT READY", _missing]};
        default {format ["%1 READY - PRESS TO LAUNCH", count _rows]};
    },
    ["rest", "warn"] select (_path && !_ready)
]]
