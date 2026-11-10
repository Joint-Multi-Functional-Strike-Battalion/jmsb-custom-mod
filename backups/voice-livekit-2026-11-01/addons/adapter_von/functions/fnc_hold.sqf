#include "script_component.hpp"
/*
 * Author: YonV
 * The talk keys (initKeybinds.inc.sqf): PTT 1-4 put the mic on that key's net
 * while held (jmfsb_voice_fnc_pttNet: PTT 1 the active net, 2-4 the nets the
 * RADIO app gave them), TALK LOCAL puts it on Direct. Under voice activation
 * that is the whole radio - hold and speak. Under push to talk they pick the
 * channel the Push To Talk key sends on, so TALK LOCAL + Push To Talk is local
 * voice without Arma's own Talk on Direct key. Two PTT keys held: the last
 * pressed talks.
 *
 * Arguments:
 * 0: Which key - HOLD_PTT or HOLD_LOCAL <STRING>
 * 1: Pressed (true) or released (false) <BOOL>
 * 2: PTT key 1..4, for HOLD_PTT <NUMBER> (optional, default 1)
 *
 * Return Value:
 * false: the key is never consumed, so Arma's own Push To Talk on the same
 * key (Caps Lock) still opens the mic <BOOL>
 *
 * Example:
 * ["ptt", true, 2] call jmfsb_adapter_von_fnc_hold
 *
 * Public: No
 */

params [["_what", HOLD_PTT, [""]], ["_down", false, [false]], ["_key", 1, [0]]];

if (_what isEqualTo HOLD_LOCAL) then {
    GVAR(holdLocal) = _down;
} else {
    private _at = GVAR(heldPtt) find _key;
    if (_at >= 0) then {GVAR(heldPtt) deleteAt _at};
    if (_down) then {GVAR(heldPtt) pushBack _key};
    // TALK LOCAL IS THE SAME KEY WITH A MODIFIER (Shift + Caps Lock): when the
    // modifier goes up before the key, the key's release arrives as PTT 1's,
    // so it ends the local hold too - the mic never stays on Direct.
    if (!_down && _key isEqualTo PTT_ACTIVE_KEY) then {GVAR(holdLocal) = false};
};

[] call FUNC(applyOpen);
false
