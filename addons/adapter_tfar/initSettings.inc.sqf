// CBA Settings [ADDON: jmfsb_adapter_tfar]
// OPERATION VALUES ONLY: how RF link quality turns into TFAR range. Which nets
// exist and who is on them come from the radio plan and RF, never from here.
// Server-forced: every client degrades voice by the same rule.

[
    QGVAR(voiceEnabled), "CHECKBOX",
    ["RF voice override", "TFAR range follows RF link quality: the set's range shrinks as the link to its net weakens and is cut when RF reaches nobody. Off: TFAR's own range, untouched."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Voice (TFAR)"],
    true,
    1,
    {[] call FUNC(applyVoice)}
] call CBA_fnc_addSetting;

[
    QGVAR(voiceCut), "SLIDER",
    ["Cut at quality", "Link quality (0-1) at or below which a net's voice is cut. 0 = only when RF says no link (SNR under its threshold)."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Voice (TFAR)"],
    [0, 0.5, DEFAULT_VOICE_CUT, 2],
    1,
    {[] call FUNC(applyVoice)}
] call CBA_fnc_addSetting;

[
    QGVAR(voiceFloor), "SLIDER",
    ["Range at the weakest link", "Share of TFAR's normal range left at the lowest quality above the cut. Range grows linearly from here to full range at quality 1."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Voice (TFAR)"],
    [0.05, 1, DEFAULT_VOICE_FLOOR, 2],
    1,
    {[] call FUNC(applyVoice)}
] call CBA_fnc_addSetting;

// --- The radio UI and the fill (milestone 2) ----------------------------------

[
    QGVAR(hideTfarUi), "CHECKBOX",
    ["Hide TFAR's radio UI", "TFAR's transmit and channel-change popups do not show; the HUD's RADIO widget and the tablet's net row and RADIO app are the radio UI. Overrides TFAR's own two hint settings for the session only - your saved TFAR settings are kept. Off: TFAR's popups as you set them."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Voice (TFAR)"],
    true,
    1,
    {[] call FUNC(tfarUi)}
] call CBA_fnc_addSetting;

[
    QGVAR(fillOnIssue), "CHECKBOX",
    ["Fill new sets from the plan", "A handheld or backpack set that carries none of the radio plan's nets when it is first seen (spawn, respawn, picked up) is loaded with the plan's fill: each plan net's frequency on its plan channel. Sets already on the plan's frequencies, captured sets and vehicle racks are left alone. Off: sets keep TFAR's frequencies until a fill is loaded."],
    ["1st Joint Multi-Functional Strike Battalion", "RF - Voice (TFAR)"],
    true,
    1
] call CBA_fnc_addSetting;
