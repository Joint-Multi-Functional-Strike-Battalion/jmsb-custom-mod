#include "script_component.hpp"

// The training areas are read, and their markers hidden, on every machine.
[] call FUNC(areas);

// The instructor's entries run on their machine; the spawning is the server's.
[QGVAR(resetPads), FUNC(resetPads)] call CBA_fnc_addEventHandler;
[QGVAR(moutCreate), FUNC(moutCreate)] call CBA_fnc_addEventHandler;
[QGVAR(moutClear), FUNC(moutClear)] call CBA_fnc_addEventHandler;
// TAC//TRAINING's patients and training areas.
[QGVAR(patientSpawn), FUNC(patientSpawn)] call CBA_fnc_addEventHandler;
[QGVAR(patientClear), FUNC(patientClear)] call CBA_fnc_addEventHandler;
[QGVAR(areaSpawn), FUNC(areaSpawn)] call CBA_fnc_addEventHandler;
[QGVAR(areaClear), FUNC(areaClear)] call CBA_fnc_addEventHandler;
// TAC//TRAINING's vehicle ranges.
[QGVAR(vehSpawn), FUNC(vehSpawn)] call CBA_fnc_addEventHandler;
[QGVAR(vehClear), FUNC(vehClear)] call CBA_fnc_addEventHandler;

if (isServer) then {
    // A training area's enemy falling, or a trainee going down inside a live
    // one, is its after-action count (FUNC(areaState)).
    addMissionEventHandler ["EntityKilled", {
        params ["_unit"];
        private _area = _unit getVariable [QGVAR(area), ""];
        if (_area isNotEqualTo "") exitWith {
            if (_unit isKindOf "CAManBase") then {[_area, "killed"] call FUNC(areaState)};
        };
        if (isPlayer _unit) then {[_unit] call FUNC(areaCasualty)};
    }];
    ["ace_unconscious", {
        params ["_unit", "_down"];
        if (_down && {isPlayer _unit}) then {[_unit] call FUNC(areaCasualty)};
    }] call CBA_fnc_addEventHandler;
};

if (!hasInterface) exitWith {};

// The TRAINING tile opens this - see EFUNC(tacpad_apps,tileData).
[APP_ID, FUNC(app)] call EFUNC(tacpad,registerApp);

// The aid stations' laptops, for anyone (FUNC(medicalLaptops)).
[] call FUNC(medicalLaptops);
