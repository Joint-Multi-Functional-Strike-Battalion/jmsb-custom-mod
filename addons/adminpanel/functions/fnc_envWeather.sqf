#include "script_component.hpp"
/*
 * Author: JMSB
 * SET WEATHER, on every machine: overcast is set everywhere, and the server
 * also sets rain, fog and wind and forces the change through at once - ZEN's
 * split, which is the one the engine syncs cleanly. Wind keeps the direction it
 * blows in now; out of a calm it blows north.
 *
 * Arguments:
 * 0: Overcast, 0-1 <NUMBER>
 * 1: Rain, 0-1 <NUMBER>
 * 2: Fog, 0-1 <NUMBER>
 * 3: Wind, m/s <NUMBER>
 * 4: Admin who set it <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [1, 1, 0.1, 14, "YonV"] call jmfsb_adminpanel_fnc_envWeather
 *
 * Public: No
 */

params ["_overcast", "_rain", "_fog", "_wind", "_by"];

0 setOvercast _overcast;

if (!isServer) exitWith {};

0 setRain _rain;
0 setFog _fog;

private _flat = [wind select 0, wind select 1, 0];
private _dir = if (vectorMagnitude _flat < ENV_WIND_CALM) then {[0, 1, 0]} else {vectorNormalized _flat};
setWind [(_dir select 0) * _wind, (_dir select 1) * _wind, true];

forceWeatherChange;

INFO_5("weather set: overcast %1 rain %2 fog %3 wind %4 by %5",_overcast,_rain,_fog,_wind,_by);
