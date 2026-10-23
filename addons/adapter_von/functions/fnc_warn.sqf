#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, once at mission start (the mission display is up): arms the VON
 * toggle block (fnc_keyDown) and tells the player when his game cannot carry
 * our voice - Push To Talk has no key, or his VON volume is near zero.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_von_fnc_warn
 *
 * Public: No
 */

(findDisplay DISPLAY_MISSION) displayAddEventHandler ["KeyDown", {_this call FUNC(keyDown)}];

if ((actionKeys ACTION_PTT) isEqualTo []) then {
    [QEGVAR(voice,note), [NOTE_TITLE, NOTE_NO_PTT]] call CBA_fnc_localEvent;
};
if ((getAudioOptionVolumes select VON_VOLUME_INDEX) < VON_VOLUME_LOW) then {
    [QEGVAR(voice,note), [NOTE_TITLE, NOTE_VON_LOW]] call CBA_fnc_localEvent;
};
