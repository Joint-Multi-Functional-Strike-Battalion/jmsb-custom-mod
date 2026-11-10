#include "script_component.hpp"
/*
 * Author: YonV
 * The aid stations' laptops (user, 2026-11-07: "ability to sync a laptop for
 * not NCOs to use"): a laptop synced to a JMSB - Medical Training module gets
 * an ACE action, MEDICAL TRAINING, for anyone - no Trainer skill, no rank.
 * Under it, each of that station's points - FREE, or its patient's state -
 * with LIGHT, MODERATE, SEVERE, ARREST, RANDOM and REMOVE; then a random
 * patient on every free point, and remove them all. Only that station's
 * points. The spawning is the server's, as the app's (FUNC(patientSpawn)).
 * Every machine with a player, once, after the modules are read.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_training_fnc_medicalLaptops
 *
 * Public: No
 */

if (!isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {};
[] call FUNC(stretchers);

{
    _x params ["_name", "_points", "_laptops"];
    if (_laptops isEqualTo [] || {_points isEqualTo []}) then {continue};
    private _root = [QGVAR(laptop), "Medical training", LAPTOP_ICON, {}, {true}, {
        params ["", "", "_args"];
        _args params ["_name", "_points"];
        private _kids = [];
        {
            private _point = _x;
            private _patient = _point getVariable [QGVAR(patient), objNull];
            private _state = "FREE";
            if (!isNull _patient) then {
                _state = if (isNil QEFUNC(medic,patientState)) then {"PATIENT"} else {MEDIC_STATE_WORDS select (([_patient] call EFUNC(medic,patientState)) # 0)};
            };
            private _presets = (PRESETS select {(_x # 0) isNotEqualTo "custom"}) apply {
                _x params ["_id", "_label"];
                [[format ["%1_%2", QGVAR(laptopPreset), _id], _label, "", {
                    params ["", "", "_a"];
                    _a params ["_point", "_id"];
                    [QGVAR(patientSpawn), [_point, _id, [], player]] call CBA_fnc_serverEvent;
                }, {true}, {}, [_point, _id]] call ace_interact_menu_fnc_createAction, [], _point]
            };
            if (!isNull _patient) then {
                _presets pushBack [[QGVAR(laptopRemove), "Remove", "", {
                    params ["", "", "_a"];
                    [QGVAR(patientClear), [_a]] call CBA_fnc_serverEvent;
                }, {true}, {}, _point] call ace_interact_menu_fnc_createAction, [], _point];
            };
            _kids pushBack [[format ["%1_%2", QGVAR(laptopPoint), _forEachIndex], format ["%1 %2: %3", _name, _forEachIndex + 1, _state], "", {}, {true}, {
                params ["", "", "_list"];
                _list
            }, _presets] call ace_interact_menu_fnc_createAction, [], _point];
        } forEach _points;
        _kids pushBack [[QGVAR(laptopAll), "Random on every free point", "", {
            params ["", "", "_pts"];
            {
                if (isNull (_x getVariable [QGVAR(patient), objNull])) then {
                    [QGVAR(patientSpawn), [_x, "random", [], player]] call CBA_fnc_serverEvent;
                };
            } forEach _pts;
        }, {true}, {}, _points] call ace_interact_menu_fnc_createAction, [], objNull];
        _kids pushBack [[QGVAR(laptopClear), "Remove every patient here", "", {
            params ["", "", "_pts"];
            {[QGVAR(patientClear), [_x]] call CBA_fnc_serverEvent} forEach _pts;
        }, {true}, {}, _points] call ace_interact_menu_fnc_createAction, [], objNull];
        _kids
    }, [_name, _points]] call ace_interact_menu_fnc_createAction;
    {[_x, 0, ["ACE_MainActions"], _root] call ace_interact_menu_fnc_addActionToObject} forEach _laptops;
} forEach GVAR(stations);
