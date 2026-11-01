#include "script_component.hpp"
/*
 * Author: JMSB
 * SET WEATHER, by remoteExec from FUNC(envApply) to the server, which checks
 * the sender is an admin (review S7), sets rain, fog and wind, forces the
 * change through at once, and passes the overcast on to every other machine
 * by remoteExec - ZEN's split, which is the one the engine syncs cleanly. A
 * client takes it only from the server. Wind keeps the direction it blows in
 * now; out of a calm it blows north.
 *
 * Arguments:
 * 0: Overcast, 0-1 <NUMBER>
 * 1: Rain, 0-1 <NUMBER>
 * 2: Fog, 0-1 <NUMBER>
 * 3: Wind, m/s <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [1, 1, 0.1, 14] remoteExecCall ["jmfsb_adminpanel_fnc_envWeather", 2]
 *
 * Public: No
 */

params [["_overcast", 0, [0]], ["_rain", 0, [0]], ["_fog", 0, [0]], ["_wind", 0, [0]]];

if (!isServer) exitWith {
    if ([] call EFUNC(common,fromServer)) then {0 setOvercast _overcast};
};
if !([] call EFUNC(common,senderIsAdmin)) exitWith {};
([] call EFUNC(common,sender)) params ["", "_admin"];
private _by = [name _admin, "server"] select isNull _admin;

0 setOvercast _overcast;
[_overcast, _rain, _fog, _wind] remoteExecCall [QFUNC(envWeather), -ADMIN_SERVER];
0 setRain _rain;
0 setFog _fog;

private _flat = [wind select 0, wind select 1, 0];
private _dir = if (vectorMagnitude _flat < ENV_WIND_CALM) then {[0, 1, 0]} else {vectorNormalized _flat};
setWind [(_dir select 0) * _wind, (_dir select 1) * _wind, true];

forceWeatherChange;

INFO_5("weather set: overcast %1 rain %2 fog %3 wind %4 by %5",_overcast,_rain,_fog,_wind,_by);
