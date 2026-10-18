#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Makes a vehicle an AD unit on the server, or moves it to a new alarm area.
 * Called on its creation (FUNC(vehicleInit)), by a Site module
 * (FUNC(moduleSite)) and for a jmfsb_airdefence battery (batteryUp). A unit
 * already known is re-filed only when the caller CLAIMS it - a module or a
 * battery wins over its automatic area, never the other way round.
 *
 * Unit record (U_* in script_component.hpp):
 *   [vehicle, gun entry, missile entry, protect radius, intercept chance
 *    (-1: the setting), area key, busy until]
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Alarm area key <STRING>
 * 2: Protect radius, -1 for its own reach under the cap <NUMBER>
 * 3: Intercept chance, -1 for the setting <NUMBER>
 * 4: Claim a unit already registered <BOOL>
 *
 * Return Value:
 * Registered <BOOL>
 *
 * Example:
 * [_vehicle, "site_1", 1500, -1, true] call jmfsb_adsite_fnc_register
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_areaKey", "", [""]], ["_radius", -1, [0]],
        ["_chance", -1, [0]], ["_claim", false, [false]]];

if (!isServer || {!alive _veh}) exitWith {false};

([_veh] call FUNC(profile)) params ["_gun", "_missile"];
if (_gun isEqualTo [] && {_missile isEqualTo []}) exitWith {false};

private _key = hashValue _veh;
private _old = GVAR(units) get _key;
if (!isNil "_old" && {!_claim}) exitWith {true};

if (_radius <= 0) then {
    _radius = ((_gun param [5, 0]) max (_missile param [5, 0]) max ADS_RADIUS_MIN) min GVAR(radiusCap);
};

// out of its old area, into the new one
if (!isNil "_old") then {
    private _was = GVAR(areas) get (_old select U_AREA);
    if (!isNil "_was") then { _was set [0, (_was select 0) - [_key]] };
};
private _area = [_areaKey, getPosASL _veh] call FUNC(area);
(_area select 0) pushBackUnique _key;

GVAR(units) set [_key, [_veh, _gun, _missile, _radius, _chance, _areaKey, -1]];

if (isNil "_old") then {
    _veh addEventHandler ["Deleted", { [_this select 0] call FUNC(unregister) }];
    _veh addEventHandler ["Killed", { [_this select 0] call FUNC(unregister) }];
    // public: the players' actions and the server's assignment read them
    if (isNil {_veh getVariable QGVAR(mode)}) then { _veh setVariable [QGVAR(mode), ADS_MODE_DEFAULT, true] };
};

// tell every firing machine there is something to defend with (FUNC(fired))
if !(missionNamespace getVariable [QGVAR(armed), false]) then {
    missionNamespace setVariable [QGVAR(armed), true, true];
};
true
