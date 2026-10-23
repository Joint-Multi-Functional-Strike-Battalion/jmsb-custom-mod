#include "script_component.hpp"
/*
 * Author: JMSB
 * Plays a radio or call sound locally, at the net's pitch (C2 low, TEAM mid,
 * A2G high, CALL two-tone; setting Pitch per net) from the net's ear (L / B /
 * R: VON cannot pan voice, so the ear pans the net's beeps and static).
 * Radio cues obey the Radio beeps setting, call cues Call beeps; both are
 * scaled by Beep volume. Cue ids: the Sounds tables of docs/DESIGN_VOICE.md -
 * txChirp, rogerBeep, squelchOpen, squelchTail, static, cutTone (the game's
 * own radio squelch and noise), netSwitch, blocked, dialTone, ringback, ring,
 * busy, connect, hangUp, joinChime, priorityWarning (our tones).
 *
 * Arguments:
 * 0: Cue id <STRING>
 * 1: Net id <STRING> (default: "", flat pitch, both ears)
 * 2: Volume factor 0..1 <NUMBER> (default: 1)
 *
 * Return Value:
 * Sound id of the (first) tone, for stopSound; -1 when nothing played <NUMBER>
 *
 * Example:
 * ["netSwitch", "C2"] call jmfsb_voice_fnc_playCue
 *
 * Public: Yes
 */

params [["_cue", "", [""]], ["_net", "", [""]], ["_factor", 1, [0]]];

if (!GVAR(active)) exitWith {NO_SOUND};
if (!hasInterface) exitWith {NO_SOUND};
private _i = CUES findIf {(_x select 0) isEqualTo _cue};
if (_i < 0) exitWith {
    WARNING_1("unknown cue %1",_cue);
    NO_SOUND
};

(CUES select _i) params ["", "_family", "_file"];
if (_family isEqualTo CUE_RADIO && !GVAR(radioBeeps)) exitWith {NO_SOUND};
if (_family isEqualTo CUE_CALL && !GVAR(callBeeps)) exitWith {NO_SOUND};

private _volume = GVAR(beepVolume) * _factor;
if (_volume <= 0) exitWith {NO_SOUND};
if (_file isEqualTo FILE_OWN) then {_file = format ["%1\%2%3", SOUND_DIR, _cue, SOUND_EXT]};

// pitch per net: radio cues only (call cues carry their own tones), never
// the static
private _pitches = [PITCH_FLAT];
if (GVAR(pitchPerNet) && _family isEqualTo CUE_RADIO && _cue isNotEqualTo "static") then {
    _pitches = switch ([_net] call FUNC(netKind)) do {
        case KIND_C2: {[PITCH_C2]};
        case KIND_TEAM: {[PITCH_TEAM]};
        case KIND_A2G: {[PITCH_A2G]};
        case KIND_CALL: {[PITCH_CALL_LOW, PITCH_CALL_HIGH]};
        default {[PITCH_FLAT]};
    };
};

private _ear = GVAR(ears) getOrDefault [_net, EAR_BOTH];
private _id = [_file, _ear, _volume, _pitches select 0] call FUNC(playSound);
if (count _pitches > 1) then {
    [FUNC(playSound), [_file, _ear, _volume, _pitches select 1], TWO_TONE_GAP_S] call CBA_fnc_waitAndExecute;
};
_id
