// CBA Settings [ADDON: jmfsb_voice]
// OPERATION VALUES ONLY: times, counts, sound switches. Nets, members and
// keys come from RF's fill and the calls, never from a setting.
//
// THE PAGES: JMSB - Voice holds the choice; JMSB - Voice (Built-in)
// everything of the game voice (here, adapter_von, adapter_livekit). The TFAR
// and ACRE pages went with those systems (DEC1, 2026-10-31).

// --- Which system carries the voice (server-forced, read once) ---------------
// WHAT carries the voice, never where or who: read at CBA_settingsInitialized
// by FUNC(selectSystem), before anything of any system starts, so a change
// takes a mission restart.
[
    QGVAR(defaultSystem), "LIST",
    ["Voice system", "Which system carries the voice. Automatic: the voice server (LiveKit, through the mod's voice extension), else the game's own VON. Game VON is the fallback for a machine without the extension; chosen, it runs whatever is loaded. A system chosen but not loaded falls back to Automatic. The server's choice is everyone's. Read at mission start."],
    [CATEGORY_VOICE, "System"],
    [SYSTEM_CHOICES, SYSTEM_CHOICE_NAMES, DEFAULT_SYSTEM_CHOICE],
    1,
    {},
    true
] call CBA_fnc_addSetting;

// --- Batteries (server-forced; user, 2026-10-30) ------------------------------
// Which kit items are a spare battery: a class list, like the jumpmaster's
// masks - what a thing IS, not where or who. RF runs the battery down
// (jmfsb_rf_batteryHours); this is what SWAP BATTERY spends.
[
    QGVAR(batteryClasses), "EDITBOX",
    ["Spare batteries", "Comma-separated. The items that are a spare radio battery: SWAP BATTERY on the RADIO app takes one out of your kit and puts a full battery in the handheld."],
    [CATEGORY_VON, "Batteries"],
    "jmfsb_mpu5_battery",
    1
] call CBA_fnc_addSetting;

// --- Mesh and calls (server-forced) -------------------------------------------
[
    QGVAR(grace), "SLIDER",
    ["Grace time (sec)", "How long a speaker whose route drops is still heard at his last quality before he is muted."],
    [CATEGORY_VON, "Mesh"],
    [0, 10, DEFAULT_GRACE_S, 1],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(ringTime), "SLIDER",
    ["Ring time (sec)", "How long a call rings before it counts as no answer (and a callback is offered)."],
    [CATEGORY_VON, "Calls"],
    [5, 60, DEFAULT_RING_S, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(callDrop), "SLIDER",
    ["Call drop time (sec)", "How long a call member can be without reach on DATA to every other member before he is dropped from the call."],
    [CATEGORY_VON, "Calls"],
    [1, 60, DEFAULT_CALL_DROP_S, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(bumpWarning), "SLIDER",
    ["FLASH bump warning (sec)", "How long the priority warning plays on a ROUTINE call before a FLASH call takes its slot."],
    [CATEGORY_VON, "Calls"],
    [1, 15, DEFAULT_BUMP_WARN_S, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(callbackExpire), "SLIDER",
    ["Callback expiry (min)", "How long the server holds a callback request before it is dropped."],
    [CATEGORY_VON, "Calls"],
    [1, 60, DEFAULT_CB_EXPIRE_MIN, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(callbacksPerPlayer), "SLIDER",
    ["Callbacks per player", "Most pending callback requests one player can be part of at once."],
    [CATEGORY_VON, "Calls"],
    [1, 10, DEFAULT_CB_PER_PLAYER, 0],
    1
] call CBA_fnc_addSetting;

// --- Sounds (each player's own) ------------------------------------------------
[
    QGVAR(radioBeeps), "CHECKBOX",
    ["Radio beeps", "TX chirp, roger beep, squelch, cut, net switch and blocked tones."],
    [CATEGORY_VON, "Sounds"],
    true,
    0
] call CBA_fnc_addSetting;

[
    QGVAR(callBeeps), "CHECKBOX",
    ["Call beeps", "Dial, ringback, ring, busy, connect, hang-up, join and priority warning tones."],
    [CATEGORY_VON, "Sounds"],
    true,
    0
] call CBA_fnc_addSetting;

[
    QGVAR(beepVolume), "SLIDER",
    ["Beep volume", "Volume of every radio and call tone, and of the static."],
    [CATEGORY_VON, "Sounds"],
    [0, MAX_BEEP_VOLUME, DEFAULT_BEEP_VOLUME, 2],
    0
] call CBA_fnc_addSetting;

[
    QGVAR(pitchPerNet), "CHECKBOX",
    ["Pitch per net", "C2 low, TEAM mid, A2G high, CALL two-tone, so the net is known before the voice starts."],
    [CATEGORY_VON, "Sounds"],
    true,
    0
] call CBA_fnc_addSetting;

[
    QGVAR(staticByQuality), "CHECKBOX",
    ["Static by quality", "Static under a radio speaker, louder as his link quality falls."],
    [CATEGORY_VON, "Sounds"],
    true,
    0
] call CBA_fnc_addSetting;

// --- RTO nets (server-forced; user, 2026-10-22: "allow rtos to add custom
// channels") ---------------------------------------------------------------
// A count, nothing else: who is on a net is the RTO's doing on the tablet.
[
    QGVAR(customNetsMax), "SLIDER",
    ["RTO nets at once", "How many nets RTOs may have made at one time. Each takes one of the game's ten custom voice channels for the rest of the mission - C2 and A2G hold two, and the calls share what is left."],
    [CATEGORY_VON, "Calls"],
    [0, CUSTOM_NETS_MAX_CAP, DEFAULT_CUSTOM_NETS_MAX, 0],
    1
] call CBA_fnc_addSetting;
