#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, each DF tick: every jammer host's POWER SYSTEM and HEAT, kept on
 * the host vehicle (QGVAR(power), JAM_POWER_FRESH) so they outlive an
 * operator getting out.
 *
 *   SOURCE   the GENERATOR while the engine runs with fuel in the tank: it
 *            carries the transmitter and puts the charge setting into the
 *            battery. Otherwise the BATTERY carries it, drawn by the mean RF
 *            out (power x duty) over the amplifier's efficiency.
 *   FLAT     the battery at 0 with no generator: off the air, told to the
 *            operator, back when the engine runs.
 *   HEAT     rises with the mean RF out as a share of the top step, sheds the
 *            cooling setting all the time; at HEAT_CUTOUT the transmitter cuts
 *            out until it has cooled to HEAT_RESUME, told both ways.
 *
 * A jammer in standby (off, cut out, or on AUTO with nothing to engage)
 * draws nothing and heats nothing. Hosts carrying two operators' jammers
 * carry both draws. Ends by putting each jammer's "tx" in step
 * (FUNC(jamUpdate)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_ew_fnc_jamPower
 *
 * Public: No
 */

if (!isServer) exitWith {};

private _now = CBA_missionTime;
private _dt = [_now - GVAR(jamPowerAt), 0] select (GVAR(jamPowerAt) < 0);
GVAR(jamPowerAt) = _now;
if (count GVAR(jammers) == 0) exitWith {};

// Host -> its jammers, as [host, [jammer, ...]] (objects key no hashmap).
private _hosts = [];
{
    private _host = _y get "host";
    if (isNull _host || {!alive _host}) then {continue};
    private _at = _hosts findIf {(_x select 0) isEqualTo _host};
    if (_at < 0) then {_hosts pushBack [_host, [_y]]} else {((_hosts select _at) select 1) pushBack _y};
} forEach GVAR(jammers);

private _full = GVAR(jamBatteryWh);
{
    _x params ["_host", "_jams"];
    (_host getVariable [QGVAR(power), JAM_POWER_FRESH]) params ["_wh", "_heat", "_flat", "_cutout"];

    private _rfW = 0;
    {
        if (_x get "tx") then {
            _rfW = _rfW + (10 ^ ((_x get "dBm") / 10)) / MW_PER_W * (_x get "dutyFrac");
        };
    } forEach _jams;
    private _draw = _rfW / JAM_PA_EFFICIENCY;
    private _gen = isEngineOn _host && {fuel _host > 0};
    private _in = if (_gen) then {_draw + ([0, GVAR(jamChargeW)] select (_wh < _full))} else {0};
    _wh = ((_wh + (_in - _draw) * _dt / SECONDS_PER_HOUR) max 0) min _full;
    _heat = ((_heat + (GVAR(jamHeatRise) * _rfW / JAM_TOP_W - GVAR(jamHeatCool)) * _dt) max 0) min HEAT_CUTOUT;

    private _told = [];
    private _wasFlat = _flat;
    _flat = !_gen && _wh <= 0;
    if (_flat && !_wasFlat) then {
        _told pushBack ["BATTERY FLAT - TRANSMITTER OFF THE AIR", "START THE ENGINE TO RUN IT OFF THE GENERATOR"];
    };
    if (!_cutout && _heat >= HEAT_CUTOUT) then {
        _cutout = true;
        _told pushBack ["THERMAL CUTOUT - TRANSMITTER OFF THE AIR", format ["IT COMES BACK AT %1%2 HEAT. LOWER THE POWER OR THE DUTY", HEAT_RESUME, "%"]];
    };
    if (_cutout && _heat <= HEAT_RESUME) then {
        _cutout = false;
        _told pushBack ["COOLED - TRANSMITTER BACK ON THE AIR", ""];
    };
    _host setVariable [QGVAR(power), [_wh, _heat, _flat, _cutout, _in, _draw, _gen]];

    {
        private _j = _x;
        [_j] call FUNC(jamUpdate);
        if !(_j get "on") then {continue};
        {
            _x params ["_detail", "_advice"];
            [_j get "operator", "EA", format ["%1 %2", _j get "devId", _detail], _advice] call FUNC(warn);
        } forEach _told;
    } forEach _jams;
} forEach _hosts;
