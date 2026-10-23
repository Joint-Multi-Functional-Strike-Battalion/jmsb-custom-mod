#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: every emitter ES can hear this DF tick, in one shape, from four
 * places -
 *
 *   rf       the RF registry's emitting nodes (RF's listener snapshot)
 *   jammer   this addon's own jammers and spoofers that are transmitting
 *   ext      emitters other addons registered with FUNC(addEmitter)
 *            (the Drone40 jammer)
 *   zone     the jamming addon's sites (jmfsb_jamming_fnc_emitters),
 *            except the GPS zones this addon laid for its own jammers
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [HASHMAP, ...] with id, object, pos (ASL), bands, txDbm, gainDbi, side
 * (string), tx, emcon, nets, intent, spread, profile, source <ARRAY>
 *
 * Example:
 * private _emitters = [] call jmfsb_ew_fnc_collect
 *
 * Public: No
 */

private _out = [];

{
    _x params ["_id", "_obj", "_pos", "_profileId", "_bands", "_txDbm", "_side", "_tx", "_emcon", "_nets", "_data"];
    private _prof = [_profileId] call EFUNC(rf,profile);
    _out pushBack createHashMapFromArray [
        ["id", _id], ["object", _obj], ["pos", _pos], ["bands", _bands],
        ["txDbm", _txDbm], ["gainDbi", _prof getOrDefault ["antennaGainDb", 0]],
        ["side", _side], ["tx", _tx], ["emcon", _emcon], ["nets", _nets],
        ["intent", _data getOrDefault [INTENT_KEY, ""]],
        ["spread", _prof getOrDefault ["spreadGainDb", 0]],
        ["profile", _profileId], ["source", SRC_RF]
    ];
} forEach GVAR(rfEmitters);

{
    private _j = _y;
    if !(_j get "tx") then {continue};
    private _host = _j get "host";
    if (isNull _host || {!alive _host}) then {continue};
    private _mode = _j get "mode";
    _out pushBack createHashMapFromArray [
        ["id", _x], ["object", _host], ["pos", getPosASL _host],
        ["bands", switch (_mode) do {
            case MODE_BARRAGE: {[_j get "band"]};
            case MODE_SPOT: {[_j get "netBand"]};
            case MODE_SWEEP: {_j get "bands"};
            default {["SAT"]};
        }],
        ["txDbm", _j get "dBm"], ["gainDbi", JAM_GAIN_DBI],
        ["side", _j get "side"], ["tx", true], ["emcon", 0], ["nets", []],
        ["intent", [INTENT_JAM, INTENT_SPOOF] select (_mode isEqualTo MODE_SPOOF)],
        ["spread", 0], ["profile", ""], ["source", SRC_JAMMER]
    ];
} forEach GVAR(jammers);

{
    _y params ["_obj", "_bands", "_dBm", "_intent", "_side"];
    if (isNull _obj || {!alive _obj}) then {continue};
    if (_obj isKindOf "AllVehicles" && {!(_obj isKindOf "CAManBase")} && {fuel _obj <= 0}) then {continue};
    _out pushBack createHashMapFromArray [
        ["id", _x], ["object", _obj], ["pos", getPosASL _obj], ["bands", _bands],
        ["txDbm", _dBm], ["gainDbi", JAM_GAIN_DBI], ["side", _side], ["tx", true],
        ["emcon", 0], ["nets", []], ["intent", _intent], ["spread", 0],
        ["profile", ""], ["source", SRC_EXTERNAL]
    ];
} forEach GVAR(external);

if (!isNil QEFUNC(jamming,emitters)) then {
    private _domainBands = createHashMapFromArray ZONE_DOMAIN_BANDS;
    {
        _x params ["_id", "_obj", "_pos", "", "_domains", "_owner"];
        if (_owner isEqualTo OWNER_TAG) then {continue};
        private _bands = [];
        {
            {_bands pushBackUnique _x} forEach (_domainBands getOrDefault [_x, []]);
        } forEach _domains;
        if (_bands isEqualTo []) then {continue};
        private _side = if (isNull _obj) then {""} else {str side group _obj};
        _out pushBack createHashMapFromArray [
            ["id", _id], ["object", _obj], ["pos", _pos], ["bands", _bands],
            ["txDbm", SITE_TX_DBM], ["gainDbi", JAM_GAIN_DBI], ["side", _side], ["tx", true],
            ["emcon", 0], ["nets", []], ["intent", INTENT_JAM], ["spread", 0],
            ["profile", ""], ["source", SRC_ZONE]
        ];
    } forEach ([] call EFUNC(jamming,emitters));
};

_out
