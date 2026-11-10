#include "script_component.hpp"
/*
 * Author: YonV
 * Puts the current VON channel where it belongs: Direct while TALK LOCAL is
 * held, a PTT key's net while it is held (the last pressed of several; PTT 1
 * is the active net, 2-4 what jmfsb_voice_fnc_pttNet says), else the open
 * channel (FUNC(openChannel)). Called on every key edge, on the net switch,
 * when a call starts or ends, and on a short tick under voice activation so
 * a call that connects is picked up without a key.
 *
 * A PTT 2-4 KEY VON WILL NOT GIVE ITS NET (PLAN_VOICE_EW_PLAY V4): its net has
 * no channel (none set, or not one of ours), or setCurrentChannel is refused
 * (a custom channel he is not yet a member of). The engine's Push To Talk
 * would then send on the channel he is on - PTT 1's net. Instead that
 * channel's voice is held off while the key is down (FUNC(holdOff)), the
 * "ptt" hook reports no key (FUNC(ptt)), and the key says why, once a press.
 *
 * Under push to talk with no key held the open channel is the active net and
 * nothing here differs from before: the net switch set the channel once and
 * the engine's channel key still does what it does.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_von_fnc_applyOpen
 *
 * Public: No
 */

if (!hasInterface || {isNull player}) exitWith {};

// the PTT 2-4 key held, and its net ("" none)
private _key = KEY_NONE;
private _keyNet = "";
private _target = switch (true) do {
    case GVAR(holdLocal): {CH_DIRECT};
    case (GVAR(heldPtt) isNotEqualTo []): {
        _key = GVAR(heldPtt) select -1;
        if (_key isEqualTo PTT_ACTIVE_KEY) then {
            _key = KEY_NONE;
            GVAR(activeCh)
        } else {
            _keyNet = [_key] call EFUNC(voice,pttNet);
            [_keyNet] call FUNC(channel)
        };
    };
    default {[] call FUNC(openChannel)};
};

private _taken = _target > CH_NONE && {currentChannel isEqualTo _target || {setCurrentChannel _target}};
if (_key isNotEqualTo KEY_NONE && !_taken) exitWith {
    [currentChannel] call FUNC(holdOff);
    if (GVAR(refusedKey) isNotEqualTo _key) then {
        GVAR(refusedKey) = _key;
        private _note = [format [NOTE_PTT_NO_NET, _key], format [NOTE_PTT_REFUSED, _key, [_keyNet] call EFUNC(voice,netName)]] select (_keyNet isNotEqualTo "");
        [NOTE_TITLE, _note] call EFUNC(notify,notify);
    };
};
GVAR(refusedKey) = KEY_NONE;
[CH_NONE] call FUNC(holdOff);
