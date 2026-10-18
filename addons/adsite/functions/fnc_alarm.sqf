#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Sounds the alarm in every area a new threat is coming down on - once per
 * salvo: an area that sounded within the Alarm Repeat stays quiet. Played with
 * playSound3D (heard on every machine) on the area's un-muted units and on its
 * loudspeakers, which FUNC(area) found once when the area was made. The sound
 * is the area's side's setting (Off or a base-game alarm), the side read off
 * its first live unit.
 *
 * Arguments:
 * 0: Unit keys the threat is coming down on <ARRAY>
 *
 * Return Value: None
 *
 * Example:
 * [_cands] call jmfsb_adsite_fnc_alarm
 *
 * Public: No
 */

params [["_keys", [], [[]]]];

private _now = CBA_missionTime;
private _done = [];
{
    private _rec = GVAR(units) get _x;
    if (isNil "_rec") then { continue };
    private _areaKey = _rec select U_AREA;
    if (_areaKey in _done) then { continue };
    _done pushBack _areaKey;

    private _area = GVAR(areas) get _areaKey;
    if (isNil "_area") then { continue };
    _area params ["_unitKeys", "_speakers", "_last"];
    if (_now - _last < GVAR(alarmCooldown)) then { continue };

    private _pick = switch (side (_rec select U_VEH)) do {
        case west: { GVAR(alarmWest) };
        case east: { GVAR(alarmEast) };
        case independent: { GVAR(alarmIndependent) };
        default { 0 };
    };
    private _sound = ADS_ALARMS param [_pick, ""];
    if (_sound isEqualTo "") then { continue };
    _area set [2, _now];

    private _sources = _speakers select {!isNull _x};
    {
        private _u = GVAR(units) get _x;
        if (isNil "_u") then { continue };
        private _veh = _u select U_VEH;
        if (alive _veh && {!(_veh getVariable [QGVAR(muted), false])}) then { _sources pushBack _veh };
    } forEach _unitKeys;

    {
        playSound3D [_sound, _x, false, getPosASL _x, ADS_ALARM_VOLUME, 1, ADS_ALARM_DISTANCE];
    } forEach _sources;
} forEach _keys;
