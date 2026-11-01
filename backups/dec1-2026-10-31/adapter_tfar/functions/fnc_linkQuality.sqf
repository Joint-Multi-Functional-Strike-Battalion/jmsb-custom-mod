#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "linkQuality", client: how well this player hears a net, 0..1 -
 * RF's quality on that net from the node of the set that hears it
 * (jmfsb_rf_fnc_quality: the best path to any peer on the net, from his
 * slice). It is the net's, not the speaker's own path. RF's "unknown" and a
 * net none of his sets hears read as 1: TFAR's own range rules there.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 *
 * Return Value:
 * Quality 0..1 <NUMBER>
 *
 * Example:
 * [_unit, "ALPHA"] call jmfsb_adapter_tfar_fnc_linkQuality
 *
 * Public: No
 */

params [["_speaker", objNull, [objNull]], ["_net", "", [""]]];

private _slot = GVAR(slots) getOrDefault [_net, []];
if (_slot isEqualTo []) exitWith {QUALITY_FULL};
private _quality = [format [NODE_ID_FORMAT, getPlayerUID player, _slot select 0], _net] call EFUNC(rf,quality);
if (_quality < 0) exitWith {QUALITY_FULL};
_quality
