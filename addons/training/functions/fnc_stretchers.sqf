#include "script_component.hpp"
/*
 * Author: YonV
 * The spawn points training patients are put on: every JMSB - Medical
 * Training module's points (user, 2026-11-07: a module where you pick the
 * names of the spawn points) - the objects named in its Spawn points, in that
 * order, then any synced to it. A synced laptop (a class whose name holds one
 * of TERMINAL_WORDS) is not a point: it is the station's terminal, from which
 * anyone can spawn patients on the station's points (FUNC(medicalLaptops)).
 * Each point is labelled with the station name and its number there. Read
 * once; the stations are kept as GVAR(stations) [[name, points, laptops], ...].
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[label, object], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_training_fnc_stretchers
 *
 * Public: No
 */

if (!isNil QGVAR(stretchers)) exitWith {GVAR(stretchers) select {!isNull (_x # 1)}};

private _fnc_terminal = {
    private _class = toLower typeOf _this;
    (TERMINAL_WORDS findIf {_x in _class}) >= 0
};

private _stations = [];
{
    private _module = _x;
    private _name = toUpper (_module getVariable ["name", ""]);
    if (_name isEqualTo "") then {_name = format ["MEDICAL %1", mapGridPosition _module]};
    private _points = [];
    private _laptops = [];
    {
        private _obj = missionNamespace getVariable [_x, objNull];
        if (_obj isEqualType objNull && {!isNull _obj}) then {
            _points pushBackUnique _obj;
        } else {
            WARNING_2("medical training '%1': no object named %2",_name,_x);
        };
    } forEach (((_module getVariable ["points", ""]) splitString ", ") select {_x isNotEqualTo ""});
    {
        if (_x isKindOf "Logic") then {continue};
        if (_x call _fnc_terminal) then {_laptops pushBackUnique _x} else {_points pushBackUnique _x};
    } forEach (synchronizedObjects _module);
    _stations pushBack [_name, _points, _laptops];
} forEach (allMissionObjects QGVAR(moduleMedical));
_stations sort true;
GVAR(stations) = _stations;

private _out = [];
{
    _x params ["_name", "_points"];
    {_out pushBack [format ["%1 - %2", _name, _forEachIndex + 1], _x]} forEach _points;
} forEach _stations;

GVAR(stretchers) = _out;
_out
