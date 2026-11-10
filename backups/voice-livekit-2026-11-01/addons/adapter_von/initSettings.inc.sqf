// CBA Settings [ADDON: jmfsb_adapter_von]
// OPERATION VALUES ONLY.

[
    QGVAR(volumeFloor), "SLIDER",
    ["Volume at the weakest link", "VON volume of a radio speaker whose link quality is just above zero; it rises to full at quality 1. At quality 0 he is muted."],
    ["JMSB - Voice (Built-in)", "VON"],
    [0, 1, DEFAULT_VOLUME_FLOOR, 2],
    1
] call CBA_fnc_addSetting;

// THE PLAYER'S OWN (user, 2026-10-24: "need a volume on the in game voip").
// Client side: each changes only what this player hears or where his mic sits.
[
    QGVAR(masterVolume), "SLIDER",
    ["Radio voice volume", "Every radio speaker you hear, on top of the link quality. Local voice (Direct) is not changed. Also on the RADIO app and the numpad - / + keys."],
    ["JMSB - Voice (Built-in)", "VON"],
    [0, 1, DEFAULT_MASTER_VOLUME, 2, true],
    false,
    {
        // Every speaker's volume is re-applied on the next frame.
        if (!isNil QGVAR(talkCh)) then {GVAR(talkCh) = createHashMap};
    }
] call CBA_fnc_addSetting;

[
    QGVAR(vad), "CHECKBOX",
    ["Voice activation", "Tick when Arma's VON is set to voice activation (Options > Audio). Your mic then sits on LOCAL or your active net - the open channel toggle - and the talk keys move it while held. Off: push to talk, as before."],
    ["JMSB - Voice (Built-in)", "VON"],
    false,
    false,
    {if (!isNil QFUNC(applyOpen)) then {[] call FUNC(applyOpen)}}
] call CBA_fnc_addSetting;

[
    QGVAR(vaCalls), "CHECKBOX",
    ["Voice activation on calls", "With voice activation on, a call you are in is your open channel for as long as it lasts: speak and the call hears you, no key."],
    ["JMSB - Voice (Built-in)", "VON"],
    true,
    false,
    {if (!isNil QFUNC(applyOpen)) then {[] call FUNC(applyOpen)}}
] call CBA_fnc_addSetting;
