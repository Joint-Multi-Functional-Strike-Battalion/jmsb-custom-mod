#include "script_component.hpp"
/*
 * Author: YonV
 * One support aircraft's lights, by where it is (user, 2026-11-01): over the
 * airfield it started from (inside AIRFIELD_LIGHTS_RADIUS, 2D) the AI keeps its
 * normal lights and the collision lights are on; anywhere else it is dark -
 * collision lights, the pilot's landing light and every turret searchlight
 * off, and the crew kept from turning them back on.
 *
 * WHY disableAI "LIGHTS". A crew flying SAFE or CARELESS - which the providers
 * set so the AI flies the task and does not break off to fight - switches its
 * lights on at night by itself. Taking the LIGHTS feature away is what keeps it
 * dark; it is given back over the airfield. Cargo is not crew: a squad
 * riding in the back keeps its own.
 *
 * WHERE THE AIRCRAFT IS LOCAL. The light commands and disableAI take a local
 * argument; every provider's crew is made on the server, so that is where this
 * runs. An aircraft that is not local here (a player took the controls, a
 * headless client owns the crew) is left alone, and a player at the controls
 * owns his own lights.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Its airfield [x, y], [] for none <ARRAY>
 *
 * Return Value:
 * It is dark <BOOL>
 *
 * Example:
 * [_veh, [1200, 3400]] call jmfsb_support_fnc_tacticalLights
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_field", [], [[]]]];

if (!alive _veh || {!local _veh} || {isPlayer driver _veh}) exitWith {false};

private _dark = _field isEqualTo [] || {_veh distance2D _field > AIRFIELD_LIGHTS_RADIUS};
// The first look counts as a change, so an aircraft starts in the right state.
private _changed = (_veh getVariable [QGVAR(dark), !_dark]) isNotEqualTo _dark;
_veh setVariable [QGVAR(dark), _dark];

private _crew = ((fullCrew _veh) select {(_x select 1) isNotEqualTo "cargo" && {!isPlayer (_x select 0)}}) apply {_x select 0};

if (!_dark) exitWith {
    if (_changed) then {
        {_x enableAI "LIGHTS"} forEach _crew;
        _veh setCollisionLight true;
    };
    false
};

// Every tick, not only on the change: a new crewman (a restored crew, a
// replacement) comes with his LIGHTS feature on.
{
    if (_x checkAIFeature "LIGHTS") then {_x disableAI "LIGHTS"};
} forEach _crew;
if (isCollisionLightOn _veh) then {_veh setCollisionLight false};
if (isLightOn _veh) then {_veh setPilotLight false};
{
    if (isLightOn [_veh, _x]) then {
        private _gunner = _veh turretUnit _x;
        if (!isNull _gunner && {!isPlayer _gunner}) then {_gunner action ["SearchlightOff", _veh]};
    };
} forEach allTurrets [_veh, false];

true
