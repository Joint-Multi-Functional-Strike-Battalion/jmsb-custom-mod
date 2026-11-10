#include "script_component.hpp"
/*
 * Author: YonV
 * One word for the screens about where the mic is: PTT (push to talk, the
 * active net on the key), or under voice activation CALL, NET or LOCAL - held
 * keys included, so the word follows the finger.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * 0: Word - OPEN_WORD_PTT, OPEN_WORD_CALL, OPEN_WORD_NET or OPEN_WORD_LOCAL <STRING>
 * 1: Voice activation is on <BOOL>
 *
 * Example:
 * ([] call jmfsb_adapter_von_fnc_openState) params ["_word", "_vad"]
 *
 * Public: Yes
 */

if (!GVAR(vad)) exitWith {[OPEN_WORD_PTT, false]};

private _word = switch (true) do {
    case GVAR(holdLocal): {OPEN_WORD_LOCAL};
    case (GVAR(heldPtt) isNotEqualTo []): {OPEN_WORD_NET};
    case (GVAR(vaCalls) && {([] call FUNC(liveCallChannel)) > CH_NONE}): {OPEN_WORD_CALL};
    case GVAR(openNet): {OPEN_WORD_NET};
    default {OPEN_WORD_LOCAL};
};

[_word, true]
