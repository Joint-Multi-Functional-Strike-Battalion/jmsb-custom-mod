#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every frame:
 * - the cut-offs (fnc_applyBlock: dead, unconscious, out of air, radio
 *   silence);
 * - his own push-to-talk: the adapter's "ptt" hook (VON: every PTT input by
 *   inputAction), its edges to fnc_transmit - one event per edge, never per
 *   frame;
 * - who is talking (fnc_talkSync): speakers who pushed their key, with the
 *   engine's report as the fallback;
 * - under each speaker he can hear on a radio net: the game's radio noise by
 *   quality (started again just before the clip ends or when his quality
 *   changes), the cut sound when his route drops mid-transmission.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], -1] call jmfsb_voice_fnc_frame
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

if (isNull player) exitWith {};

[] call FUNC(applyBlock);

([] call HOOK("ptt")) params [["_down", false, [false]], ["_net", "", [""]]];
if (_down isNotEqualTo GVAR(pttDown)) then {
    GVAR(pttDown) = _down;
    [_down, _net] call FUNC(transmit);
};

[] call FUNC(talkSync);

// under the voice: static by quality, the cut
{
    _x params ["_unit", "_net"];
    if (_unit isEqualTo player || !(([_net] call FUNC(netKind)) in MESH_KINDS)) then {continue};
    private _key = (getPlayerUID _unit) + "|" + _net;
    (GVAR(staticNext) getOrDefault [_key, [0, 0, NO_SOUND]]) params ["_next", "_was", "_id"];
    private _q = [_unit, _net] call FUNC(heard);
    if (_was > 0 && _q <= 0) then {["cutTone", _net] call FUNC(playCue)};
    private _want = GVAR(staticByQuality) && GVAR(radioBeeps) && GVAR(beepVolume) > 0 && _q > 0 && _q < 1;
    if (_id > NO_SOUND && (!_want || _q isNotEqualTo _was)) then {
        stopSound _id;
        _id = NO_SOUND;
    };
    if (_want && (_id isEqualTo NO_SOUND || time >= _next)) then {
        _id = ["static", _net, 1 - _q] call FUNC(playCue);
        _next = time + STATIC_CLIP_S;
    };
    GVAR(staticNext) set [_key, [_next, _q, _id]];
} forEach GVAR(talkers);
