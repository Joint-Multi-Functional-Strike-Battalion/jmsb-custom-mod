#include "script_component.hpp"
/*
 * Author: JMSB
 * The voice net a speaker is on when he talks on a VON channel: Group = his
 * TEAM net, Vehicle = VEH, Direct = DIRECT, the C2 channel = his own C2-kind
 * net, the A2G channel = his own A2G-kind net, a CALL channel = its key
 * (CALL n). Global, Side and Command are no net.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: VON channel <NUMBER>
 *
 * Return Value:
 * Net id, "" for none <STRING>
 *
 * Example:
 * [_unit, 6] call jmfsb_adapter_von_fnc_netOf
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_ch", CH_NONE, [0]]];

if (_ch isEqualTo CH_GROUP) exitWith {[_unit] call EFUNC(voice,teamNet)};
if (_ch isEqualTo CH_VEHICLE) exitWith {NET_VEH};
if (_ch isEqualTo CH_DIRECT) exitWith {NET_DIRECT};
if (_ch <= CH_DIRECT) exitWith {""};

private _i = GVAR(channelMap) findIf {(_x select 1) isEqualTo (_ch - CUSTOM_BASE)};
if (_i < 0) exitWith {""};
private _key = (GVAR(channelMap) select _i) select 0;
if (_key isEqualTo KEY_C2) exitWith {[_unit] call EFUNC(voice,c2Net)};
if (_key isEqualTo KEY_A2G) exitWith {[_unit] call EFUNC(voice,a2gNet)};
_key
