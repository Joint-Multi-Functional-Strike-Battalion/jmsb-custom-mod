#include "script_component.hpp"
/*
 * Author: JMSB
 * A talk key went down or up (initKeybinds.inc.sqf): PTT 1-4 (held in press
 * order, the last pressed wins) or TALK LOCAL. The mic follows (FUNC(mic));
 * the voice core reads which net is keyed through the "ptt" hook
 * (FUNC(ptt)) and sends the key edge to the net itself. TALK LOCAL is the
 * same key with a modifier (Shift + Caps Lock): when the modifier goes up
 * before the key, the key's release arrives as PTT 1's, so it ends the local
 * hold too - the mic never stays open.
 *
 * Arguments:
 * 0: What: "ptt" or "local" <STRING>
 * 1: Down <BOOL>
 * 2: PTT key 1..4, for "ptt" <NUMBER> (default: 1)
 *
 * Return Value:
 * false - the key is not consumed; Arma's own Push To Talk may share it <BOOL>
 *
 * Example:
 * ["ptt", true, 1] call jmfsb_adapter_livekit_fnc_hold
 *
 * Public: No
 */

params [["_what", HOLD_PTT, [""]], ["_down", false, [false]], ["_key", PTT_ACTIVE_KEY, [0]]];

if (_what isEqualTo HOLD_LOCAL) then {
    GVAR(holdLocal) = _down;
} else {
    private _at = GVAR(heldPtt) find _key;
    if (_at >= 0) then {GVAR(heldPtt) deleteAt _at};
    if (_down) then {GVAR(heldPtt) pushBack _key};
    if (!_down && _key isEqualTo PTT_ACTIVE_KEY) then {GVAR(holdLocal) = false};
};

[] call FUNC(mic);
false
