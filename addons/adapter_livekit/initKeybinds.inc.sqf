// THE TALK KEYS under the voice server (user, 2026-10-31: LiveKit is the
// voice) - the same keys as under the game VON (user, 2026-10-30): every talk
// key is Caps Lock with a modifier. Here the extension opens the mic, not the
// engine: a key down opens it on its net (FUNC(hold), FUNC(mic)), the voice
// core sends the key edge to the net (its "ptt" hook, FUNC(ptt)), and a key
// up closes it. Caps Lock still reaches Arma's own Push To Talk, which sends
// nothing: every game channel's voice is off here (FUNC(vonOff)). All CBA
// keybinds, rebindable.
#include "\a3\ui_f\hpp\definedikcodes.inc"

for "_i" from 1 to count PTT_DEFAULT_KEYS do {
    private _keyName = PTT_DEFAULT_NAMES select (_i - 1);
    [
        JMFSB_CATEGORY,
        format ["%1_%2", QGVAR(ptt), _i],
        [
            format ["Voice: PTT %1%2 (hold)", _i, ["", " - active net"] select (_i isEqualTo 1)],
            [
                format ["While held your mic is open on the net PTT %1 is set to on the tablet's RADIO app (net %1 of your list until you set one). %2 by default.", _i, _keyName],
                format ["While held your mic is open on your active net. %1 by default.", _keyName]
            ] select (_i isEqualTo 1)
        ],
        compile format ["[""%1"", true, %2] call %3", HOLD_PTT, _i, QFUNC(hold)],
        compile format ["[""%1"", false, %2] call %3", HOLD_PTT, _i, QFUNC(hold)],
        [PTT_DEFAULT_KEYS select (_i - 1), PTT_DEFAULT_MODS select (_i - 1)]
    ] call CBA_fnc_addKeybind;
};

[
    JMFSB_CATEGORY,
    QGVAR(talkLocal),
    ["Voice: talk local (hold)", format ["While held your mic is open to the people round you - full beside you, fading to nothing at the local voice range; crew of your vehicle hear you whatever the range. %1 by default.", LOCAL_DEFAULT_NAME]],
    {[HOLD_LOCAL, true] call FUNC(hold)},
    {[HOLD_LOCAL, false] call FUNC(hold)},
    [LOCAL_DEFAULT_KEY, LOCAL_DEFAULT_MODS]
] call CBA_fnc_addKeybind;
