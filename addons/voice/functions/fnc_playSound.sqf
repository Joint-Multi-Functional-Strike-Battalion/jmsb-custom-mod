#include "script_component.hpp"
/*
 * Author: JMSB
 * Plays one sound file on this machine only. Both ears: playSoundUI. One
 * ear: a local playSound3D placed EAR_OFFSET_M to that side of the camera,
 * so the engine pans it. The file is an addon path with no leading
 * backslash (ours under the voice addon, or the game's own).
 *
 * Arguments:
 * 0: File <STRING>
 * 1: Ear "L" | "B" | "R" <STRING>
 * 2: Volume <NUMBER>
 * 3: Pitch <NUMBER>
 *
 * Return Value:
 * Sound id, for stopSound <NUMBER>
 *
 * Example:
 * ["A3\Dubbing_Radio_F\sfx\in2a.ogg", "L", 1, 0.8] call jmfsb_voice_fnc_playSound
 *
 * Public: No
 */

params [["_file", "", [""]], ["_ear", EAR_BOTH, [""]], ["_volume", 1, [0]], ["_pitch", PITCH_FLAT, [0]]];

if (_ear isEqualTo EAR_BOTH) exitWith {
    playSoundUI [_file, _volume, _pitch]
};

private _side = [EAR_OFFSET_M, -EAR_OFFSET_M] select (_ear isEqualTo EAR_LEFT);
private _pos = AGLToASL (positionCameraToWorld [_side, 0, 0]);
playSound3D [_file, objNull, false, _pos, _volume, _pitch, EAR_RANGE_M, 0, true]
