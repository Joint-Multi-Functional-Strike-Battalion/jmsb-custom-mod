#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "channel": the VON channel a net is on - TEAM 3 (Group), VEH 4
 * (Vehicle), DIRECT 5, C2-kind, A2G and CALL nets on their custom channel
 * (5 + custom id).
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * VON channel number, -1 when it has none (yet) <NUMBER>
 *
 * Example:
 * ["C2"] call jmfsb_adapter_von_fnc_channel
 *
 * Public: No
 */

params [["_net", "", [""]]];

private _kind = [_net] call EFUNC(voice,netKind);
if (_kind isEqualTo KIND_TEAM) exitWith {CH_GROUP};
if (_kind isEqualTo KIND_VEH) exitWith {CH_VEHICLE};
if (_kind isEqualTo KIND_DIRECT) exitWith {CH_DIRECT};

private _key = [_net] call FUNC(channelKey);
private _i = GVAR(channelMap) findIf {(_x select 0) isEqualTo _key};
if (_key isEqualTo "" || _i < 0) exitWith {CH_NONE};
CUSTOM_BASE + ((GVAR(channelMap) select _i) select 1)
