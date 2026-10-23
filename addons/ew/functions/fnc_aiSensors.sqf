#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the enemy AI's DF sensors this tick (DESIGN_EW "Both ways", AI EW
 * BASIC: "ES reacts to fixes on player transmitters"). RF counts no AI sets
 * (jmfsb_rf_aiNodes is off and no adapter registers them), so the AI does not
 * hear through RF's listener as players' sets do; it hears through the same
 * rules instead - each AI group of the side whose radio (FUNC(aiSet)) has a
 * DF-capable RF profile is one sensor at that man's head, priced from the
 * profile exactly as FUNC(sensor) prices a player's set: the class's bearing
 * error, the profile's bands, RX sensitivity and gain, an EW Receiver in his
 * kit making it the dedicated 2 deg all-band set. Player-led groups are not
 * here: their sets are RF nodes already.
 *
 * Each sensor carries where its GPS says it is (QGVAR(gps), FUNC(spoof)): the
 * bearing is measured from where the man stands, the cut is plotted from
 * where he thinks he stands - a spoofed set's fixes land off target.
 *
 * Arguments:
 * 0: The side, as RF writes it ("EAST") <STRING>
 *
 * Return Value:
 * [sensors [[side, id, pos ASL, error deg, bands, sens dBm, gain dBi,
 *  GPS pos ASL, true], ...], their men <ARRAY of OBJECTs>] <ARRAY>
 *
 * Example:
 * (["EAST"] call jmfsb_ew_fnc_aiSensors) params ["_sensors", "_men"]
 *
 * Public: No
 */

params [["_side", "", [""]]];

private _sideObj = [_side] call EFUNC(common,sideFromText);
private _sensors = [];
private _men = [];
if (_sideObj isEqualTo sideUnknown) exitWith {[_sensors, _men]};

{
    if ((side _x) isNotEqualTo _sideObj) then {continue};
    private _leader = leader _x;
    if (isNull _leader || !alive _leader || isPlayer _leader) then {continue};

    ([_x] call FUNC(aiSet)) params ["_man", "_profile"];
    if (isNull _man) then {continue};
    private _i = DF_PROFILES findIf {(_x select 0) isEqualTo _profile};
    if (_i < 0) then {continue};

    private _err = (DF_PROFILES select _i) select 1;
    private _prof = [_profile] call EFUNC(rf,profile);
    private _bands = _prof getOrDefault ["bands", []];
    if (([_man] call FUNC(kit)) get "receiver") then {
        _err = DF_ERR_DEDICATED;
        _bands = BANDS_ALL;
    };

    private _pos = eyePos _man;
    private _offset = (_man getVariable [QGVAR(gps), [GPS_GOOD, [0, 0]]]) select 1;
    _sensors pushBack [
        _side, "ai_" + hashValue _man, _pos, _err, _bands,
        _prof getOrDefault ["rxSensDbm", EXPOSURE_SENS_DBM], _prof getOrDefault ["antennaGainDb", 0],
        _pos vectorAdd [_offset select 0, _offset select 1, 0], true
    ];
    _men pushBack _man;
} forEach allGroups;

[_sensors, _men]
