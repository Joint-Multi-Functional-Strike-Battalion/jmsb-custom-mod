#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: sets how loud the local player hears a speaker
 * (setPlayerVoNVolume), for the channel the speaker is talking on now. VON's
 * volume is per speaker, not per channel, so it follows his channel:
 * - not talking, Direct or Global: full (his 3D voice is never touched);
 * - Vehicle: full between crew of the same vehicle, else muted (passengers
 *   are muted by volume - no command limits the channel to crew);
 * - Group and the custom channels: from the mesh quality the voice core
 *   gave for his net - muted at 0, the "Volume at the weakest link" just
 *   above it, rising to full at 1;
 * - Side and Command (disabled): muted.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: VON channel he is talking on, -1 none <NUMBER>
 * 2: Net he keyed, "" to work it out from the channel <STRING> (default: "")
 *
 * Return Value:
 * Volume set <NUMBER>
 *
 * Example:
 * [_unit, 6] call jmfsb_adapter_von_fnc_applyVolume
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_ch", CH_NONE, [0]], ["_net", "", [""]]];

if (isNull _unit || _unit isEqualTo player) exitWith {VOLUME_FULL};

private _volume = VOLUME_FULL;
switch (true) do {
    case (_ch in [CH_SIDE, CH_COMMAND]): {_volume = VOLUME_MUTE};
    case (_ch isEqualTo CH_VEHICLE): {
        private _mine = [player] call EFUNC(voice,crewOf);
        if (isNull _mine || {_mine isNotEqualTo ([_unit] call EFUNC(voice,crewOf))}) then {_volume = VOLUME_MUTE};
    };
    case (_ch isEqualTo CH_GROUP || _ch > CH_DIRECT): {
        if (_net isEqualTo "") then {_net = [_unit, _ch] call FUNC(netOf)};
        private _q = GVAR(q) getOrDefault [(getPlayerUID _unit) + "|" + _net, 0];
        _volume = if (_q > 0) then {GVAR(volumeFloor) + (VOLUME_FULL - GVAR(volumeFloor)) * _q} else {VOLUME_MUTE};
    };
};

_unit setPlayerVoNVolume _volume;
_volume
