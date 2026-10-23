#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_budget: the full one-way budget from one node to another as they stand
 * now (server). Not cached: it casts fresh, for tools and the range checks,
 * not for the tick. On SAT it is the satellite budget
 * (jmfsb_rf_fnc_satBudget, open sky at both ends checked fresh).
 *
 * Arguments:
 * 0: TX node id <STRING>
 * 1: RX node id <STRING>
 * 2: Band (optional, default the first band both profiles share) <STRING>
 * 3: Net id, for the noise hooks (optional, default "") <STRING>
 *
 * Return Value:
 * [rx dBm, snr dB, quality 0..1], [] when a node or a common band is missing <ARRAY>
 *
 * Example:
 * ["node_a", "node_b"] call jmfsb_rf_fnc_budget
 *
 * Public: Yes
 */

params [["_txId", "", [""]], ["_rxId", "", [""]], ["_band", "", [""]], ["_net", "", [""]]];

if (!isServer) exitWith {[]};

private _tx = GVAR(nodes) getOrDefault [_txId, createHashMap];
private _rx = GVAR(nodes) getOrDefault [_rxId, createHashMap];
if (count _tx == 0 || {count _rx == 0}) exitWith {[]};

private _profTx = GVAR(profiles) get (_tx get "profile");
private _profRx = GVAR(profiles) get (_rx get "profile");
if (_band isEqualTo "") then {
    _band = ((_profTx get "bands") arrayIntersect (_profRx get "bands")) param [0, ""];
};
if (_band isEqualTo "" || {!(_band in (_profTx get "bands"))} || {!(_band in (_profRx get "bands"))}) exitWith {[]};

private _objTx = _tx get "object";
private _objRx = _rx get "object";
private _posTx = [_objTx] call FUNC(nodePos);
private _posRx = [_objRx] call FUNC(nodePos);

// SAT is the satellite: no distance, open sky at both ends, cast fresh
if (_band isEqualTo SAT_BAND) exitWith {
    [
        [_posRx, SAT_BAND, _net, _profRx get "spreadGainDb"] call FUNC(noise),
        _profRx get "rxSensDbm",
        ([_objTx, _posTx] call FUNC(openSky)) && {[_objRx, _posRx] call FUNC(openSky)}
    ] call FUNC(satBudget)
};

private _parts = [_posTx, _posRx, _band, _objTx, _objRx] call FUNC(pathLoss);
private _loss = (_parts select 0) + (_parts select 1) + (_parts select 2)
    + ([_objTx] call FUNC(bodyLoss)) + ([_objRx] call FUNC(bodyLoss));
private _noise = [_posRx, _band, _net, _profRx get "spreadGainDb"] call FUNC(noise);

[
    _profTx get "txPowerDbm", _profTx get "antennaGainDb", _profRx get "antennaGainDb",
    _loss, _noise, _profRx get "rxSensDbm"
] call FUNC(linkBudget)
