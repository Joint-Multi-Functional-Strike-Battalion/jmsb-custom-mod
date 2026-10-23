#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "quality", client: the quality the local player hears a speaker
 * at on a net (grace time and mute already applied by the voice core). Kept
 * for when he talks on that net; applied at once if he is talking on it now
 * (keyed by his own event, else as getPlayerChannel reports him).
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 * 2: Quality 0..1 <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, "C2", 0.6] call jmfsb_adapter_von_fnc_quality
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]], ["_q", 0, [0]]];

if (isNull _unit) exitWith {};
private _uid = getPlayerUID _unit;
GVAR(q) set [_uid + "|" + _net, _q];

private _ch = GVAR(talkCh) getOrDefault [_uid, CH_NONE];
if (_ch <= CH_NONE) exitWith {};
private _talkNet = (GVAR(keyed) getOrDefault [_uid, [objNull, CH_NONE, ""]]) select 2;
if (_talkNet isEqualTo "") then {_talkNet = [_unit, _ch] call FUNC(netOf)};
if (_talkNet isEqualTo _net) then {
    [_unit, _ch, _net] call FUNC(applyVolume);
};
