#include "script_component.hpp"
/*
 * Author: YonV
 * How loud, and in which ear, the local player hears a speaker now - the mix
 * (docs/DESIGN_VOICE_LIVEKIT.md). Everyone's audio is in the one room; this
 * is who hears whom:
 * - RADIO: keyed on a net (FUNC(keyed)) THE LISTENER IS ON NOW (the voice
 *   core's jmfsb_voice_myNets - a net he left, or a CALL slot reused by
 *   another call, is not heard), at the quality the voice core gave him on
 *   it (FUNC(quality): RF link, grace, mute), in the ear the net is set to.
 * - LOCAL: by distance, always (a man on the radio beside you is heard
 *   beside you too): full in the same vehicle, else falling to nothing at
 *   the local voice range, in the ear he stands to.
 * The louder of the two wins, with its ear.
 * The listener's own cut-offs (radio silence, unconscious, out of air) close
 * only his mic (FUNC(mic)), as under the game VON - he still hears. Dead, he
 * hears nothing.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * [gain 0..1, pan -1..1] <ARRAY>
 *
 * Example:
 * [_unit] call jmfsb_adapter_livekit_fnc_gainOf
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {isNull player} || {!alive player}) exitWith {[0, 0]};

private _gain = 0;
private _pan = 0;
private _uid = getPlayerUID _unit;

// radio
(GVAR(keyed) getOrDefault [_uid, [objNull, LOCAL_NET]]) params ["", "_net"];
if (_net isNotEqualTo LOCAL_NET && {(((missionNamespace getVariable [QEGVAR(voice,myNets), []]) findIf {(_x select 0) isEqualTo _net}) >= 0)}) then {
    private _q = GVAR(q) getOrDefault [_uid + "|" + _net, 0];
    if (_q > 0) then {
        _gain = _q;
        _pan = GVAR(earPans) getOrDefault [(missionNamespace getVariable [QEGVAR(voice,ears), createHashMap]) getOrDefault [_net, "B"], 0];
    };
};

// local
private _local = 0;
private _vehicle = objectParent player;
if (!isNull _vehicle && {_vehicle isEqualTo objectParent _unit}) then {
    _local = 1;
} else {
    private _range = GVAR(localRange) max LOCAL_RANGE_MIN;
    private _d = (eyePos player) vectorDistance (eyePos _unit);
    if (_d < _range) then {_local = (1 - _d / _range) ^ LOCAL_CURVE};
};
if (_local > _gain) then {
    _gain = _local;
    _pan = sin (player getRelDir _unit);
};

[_gain, _pan]
