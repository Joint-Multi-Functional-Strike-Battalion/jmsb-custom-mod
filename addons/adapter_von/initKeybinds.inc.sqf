// The voice keys (user, 2026-10-24: "a cleaner way to do key binds so make new
// ones that are voip and local ... a button to toggle voice activation on one
// voip and local ... need a volume on the in game voip"). All CBA keybinds under
// the JMSB category, player-rebindable, on the free numpad keys beside the
// device block (SPEC_TACNET D16: 0-9 and . are taken).
//
// The engine owns the microphone: no script starts a transmission. These keys
// move the CURRENT CHANNEL, which is what Arma's own voice activation transmits
// on and what the Push To Talk key sends on - see FUNC(openChannel).
#include "\a3\ui_f\hpp\definedikcodes.inc"

// PTT 1-4 (user, 2026-10-30), like the MPU5's Dual PTT: PTT 1 is the active
// net, Caps Lock - the same key as Arma's own Push To Talk, which is what
// opens the mic under VON; the bind is not consumed, so both run. PTT 2-4 talk
// on the net the tablet's RADIO app gives each (net 2, 3, 4 of the list by
// default). EVERY TALK KEY IS CAPS LOCK WITH A MODIFIER (user, 2026-10-30:
// "make specific keybinds for our built in von to use for push to talk and
// local"): the engine sees Caps Lock and opens the mic whatever else is
// held, and the modifier says where the mic sits - Ctrl, Alt, Shift+Ctrl
// for PTT 2-4, Shift for TALK LOCAL. So each key works on its own under
// push to talk, with Arma's Push To Talk left on Caps Lock.
for "_i" from 1 to count PTT_DEFAULT_KEYS do {
    private _keyName = PTT_DEFAULT_NAMES select (_i - 1);
    [
        JMFSB_CATEGORY,
        format ["%1_%2", QGVAR(ptt), _i],
        [
            format ["Voice: PTT %1%2 (hold)", _i, ["", " - active net"] select (_i isEqualTo 1)],
            [
                format ["While held your mic is on the net PTT %1 is set to on the tablet's RADIO app (net %1 of your list until you set one). %2 by default: Caps Lock is Arma's Push To Talk and opens the mic, the modifier picks the net. Keep Arma's Push To Talk on Caps Lock, or bind this key under it too. With voice activation the key alone is the radio.", _i, _keyName],
                format ["While held your mic is on your active net. %1, the same key as Arma's Push To Talk: both run, the net is picked and the mic opens. With voice activation: hold and speak.", _keyName]
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
    ["Voice: talk local (hold)", format ["While held your mic is on Direct - the people round you. %1 by default: Caps Lock is Arma's Push To Talk and opens the mic, Shift puts it on Direct, so the one key is local voice. With voice activation: hold and speak.", LOCAL_DEFAULT_NAME]],
    {[HOLD_LOCAL, true] call FUNC(hold)},
    {[HOLD_LOCAL, false] call FUNC(hold)},
    [LOCAL_DEFAULT_KEY, LOCAL_DEFAULT_MODS]
] call CBA_fnc_addKeybind;

[
    JMFSB_CATEGORY,
    QGVAR(openToggle),
    ["Voice: open channel NET / LOCAL", "Voice activation only: where your open mic sits when no talk key is held - your active net, or LOCAL (Direct). A live call takes it while it lasts. No default key."],
    {[] call FUNC(openToggle)},
    {false},
    [-1, [false, false, false]]
] call CBA_fnc_addKeybind;

[
    JMFSB_CATEGORY,
    QGVAR(volumeDown),
    ["Voice: radio volume down", "Radio speakers 10% quieter. Local voice is not changed. No default key (numpad - is TROOPS IN CONTACT since 2026-10-30) - bind one in Configure Addons."],
    {[-VOLUME_STEP] call FUNC(volumeStep)},
    {false},
    [KEY_NONE, [false, false, false]]
] call CBA_fnc_addKeybind;

[
    JMFSB_CATEGORY,
    QGVAR(volumeUp),
    ["Voice: radio volume up", "Radio speakers 10% louder, to full. No default key (numpad + is voice activation since 2026-10-30) - bind one in Configure Addons."],
    {[VOLUME_STEP] call FUNC(volumeStep)},
    {false},
    [KEY_NONE, [false, false, false]]
] call CBA_fnc_addKeybind;
