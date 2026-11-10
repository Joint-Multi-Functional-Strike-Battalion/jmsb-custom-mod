#include "script_component.hpp"
/*
 * Author: YonV
 * OPEN CHANNEL: NET or LOCAL - where an open mic sits when no talk key is held,
 * under voice activation (FUNC(openChannel)). A key and a RADIO app button.
 * Under push to talk it changes nothing audible and says so.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [] call jmfsb_adapter_von_fnc_openToggle
 *
 * Public: No
 */

GVAR(openNet) = !GVAR(openNet);
[] call FUNC(applyOpen);

private _word = [OPEN_WORD_LOCAL, OPEN_WORD_NET] select GVAR(openNet);
private _text = if (GVAR(vad)) then {
    format [NOTE_OPEN, _word]
} else {
    format [NOTE_OPEN_PTT, _word]
};
[NOTE_TITLE, _text] call EFUNC(notify,notify);
[QEGVAR(voice,netsChanged), []] call CBA_fnc_localEvent;
true
