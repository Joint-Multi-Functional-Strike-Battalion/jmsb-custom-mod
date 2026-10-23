#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the frequency a track is heard on - the MHz of the emitter's net on
 * the track's band (jmfsb_rf_fnc_netFreq), the frequency a targeted jammer
 * must sit on to hit that net. An emitter on no net of that band (a jammer, a
 * drone's video) is put on a frequency of its own id. Kept on the track once
 * its emitter has been seen, so it does not move while the track lives.
 *
 * Arguments:
 * 0: Track <HASHMAP>
 *
 * Return Value:
 * MHz, 0 when the band has none <NUMBER>
 *
 * Example:
 * [_track] call jmfsb_ew_fnc_trackMhz
 *
 * Public: No
 */

params [["_t", createHashMap, [createHashMap]]];

private _known = _t getOrDefault ["mhz", -1];
if (_known >= 0) exitWith {_known};

private _band = _t getOrDefault ["band", ""];
private _emitter = _t getOrDefault ["emitter", ""];
private _e = GVAR(lastEmitters) getOrDefault [_emitter, createHashMap];
private _nets = (_e getOrDefault ["nets", []]) select {([_x] call EFUNC(rf,netBand)) isEqualTo _band};
// A set's own net before the shared DATA net, as spot takes it.
private _key = ((_nets - [NET_DATA]) + _nets) param [0, _emitter];
private _mhz = [_key, _band] call EFUNC(rf,netFreq);
if (count _e > 0) then {_t set ["mhz", _mhz]};
_mhz
