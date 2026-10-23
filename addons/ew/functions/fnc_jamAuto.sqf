#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, every AUTO_CHECK_S: AUTO-ENGAGE. A jammer on OPERATION AUTO
 * transmits only while something it can hit is in its reach (the reach
 * setting, or its GPS / spoof radius):
 *
 *   a HOSTILE DRONE - a live UAV of a side hostile to the operator's - or
 *   a HOSTILE EMITTER the side has a fresh track on, on a band the jammer is
 *            working (its barrage band, a sweep's bands, a spot's net band;
 *            targeted, within the tuned bandwidth). The track is what tells
 *            the side it is there; whether the jammer reaches it is
 *            measured from where the emitter is, as the noise itself is.
 *
 * Otherwise it is in STANDBY: no noise, no draw, no heat. What engaged it is
 * kept for the panel. Called from FUNC(tick); does nothing between checks.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_ew_fnc_jamAuto
 *
 * Public: No
 */

if (!isServer) exitWith {};

private _now = CBA_missionTime;
if (_now < GVAR(jamAutoAt)) exitWith {};
GVAR(jamAutoAt) = _now + AUTO_CHECK_S;

private _uavs = allUnitsUAV select {alive _x};
private _fresh = AUTO_CHECK_S + GVAR(dfTick);
{
    private _j = _y;
    if ((_j get "operation") isNotEqualTo OP_AUTO) then {continue};
    private _host = _j get "host";
    private _why = "";
    if ((_j get "on") && {!isNull _host} && {alive _host}) then {
        private _sideObj = [_j get "side"] call EFUNC(common,sideFromText);
        private _from = getPosASL _host;
        private _radius = _j getOrDefault ["radius", 0];
        private _reach = [GVAR(jamRange), _radius] select (_radius > 0);

        private _drone = _uavs findIf {(_sideObj getFriend side _x) < HOSTILE_BELOW && {(_x distance _host) <= _reach}};
        if (_drone >= 0) exitWith {_why = AUTO_WHY_DRONE};

        private _mode = _j get "mode";
        private _bands = switch (_mode) do {
            case MODE_BARRAGE: {[_j get "band"]};
            case MODE_SPOT: {[_j get "netBand"]};
            case MODE_SWEEP: {_j get "bands"};
            default {[]};
        };
        private _targeted = _mode isEqualTo MODE_BARRAGE && {(_j get "filter") isEqualTo FILTER_TARGETED};
        {
            private _t = _y;
            if ((_now - (_t get "last")) > _fresh || {!((_t get "band") in _bands)}) then {continue};
            if (_targeted && {abs (([_t] call FUNC(trackMhz)) - (_j get "freq")) > TARGET_BW_MHZ / 2}) then {continue};
            private _e = GVAR(lastEmitters) getOrDefault [_t get "emitter", createHashMap];
            if (count _e == 0 || {((_e get "pos") distance _from) > _reach}) then {continue};
            if ((_sideObj getFriend ([_e get "side"] call EFUNC(common,sideFromText))) < HOSTILE_BELOW) exitWith {
                _why = format ["TRACK %1", _x];
            };
        } forEach (GVAR(tracks) getOrDefault [_j get "side", createHashMap]);
    };
    private _engaged = _why isNotEqualTo "";
    _j set ["engagedWhy", _why];
    if (_engaged isEqualTo (_j get "engaged")) then {continue};
    _j set ["engaged", _engaged];
    [_j] call FUNC(jamUpdate);
} forEach GVAR(jammers);
