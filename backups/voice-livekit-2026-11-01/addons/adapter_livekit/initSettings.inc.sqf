// CBA Settings [ADDON: jmfsb_adapter_livekit]
// The voice server: its address (set it in the server's settings), and the
// API key and secret it was started with (the Pelican egg's LIVEKIT_API_KEY /
// LIVEKIT_API_SECRET). Only the server reads them, to sign players in
// (FUNC(srvRoomToken), FUNC(srvEchoToken)), BUT CBA COPIES SERVER VALUES TO
// EVERY CLIENT (review S9 / R4): leave the key and secret EMPTY and set them
// in the Arma server's environment instead, JMSB_LIVEKIT_KEY and
// JMSB_LIVEKIT_SECRET (the server egg's variables) - the extension reads them
// there when the settings are empty.

[
    QGVAR(url), "EDITBOX",
    ["Voice server address", "The LiveKit server players join, with the egg's main port (7880): ws URL, or wss with the node's name when the egg's Encryption (TLS) is on. Empty: no echo test."],
    ["JMSB - Voice (Built-in)", "Voice server (LiveKit)"],
    "",
    1
] call CBA_fnc_addSetting;

[
    QGVAR(key), "EDITBOX",
    ["API key", "Leave EMPTY: set JMSB_LIVEKIT_KEY in the Arma server's environment (the server egg's variable) instead. The voice server's API key (the voice egg's LIVEKIT_API_KEY); this setting is copied to every client."],
    ["JMSB - Voice (Built-in)", "Voice server (LiveKit)"],
    "",
    1
] call CBA_fnc_addSetting;

// THE PLAYER'S OWN DEVICES (user, 2026-10-31: the echo came out of the
// speakers, not the headset the game plays on): the extension opens Windows'
// default microphone and speakers unless told a name. Each player's own
// (not server-forced); part of the device's name as Windows lists it. The
// names this machine has are in the RPT at mission start ("voice devices").
[
    QGVAR(inputDevice), "EDITBOX",
    ["Microphone", "Part of the microphone's name as Windows lists it (e.g. Headset). Empty: Windows' default. Your machine's names are in your RPT at mission start, after 'voice devices'."],
    ["JMSB - Voice (Built-in)", "Voice server (LiveKit)"],
    "",
    0,
    {[] call FUNC(applyDevices)}
] call CBA_fnc_addSetting;

[
    QGVAR(outputDevice), "EDITBOX",
    ["Speakers", "Part of the speakers' or headset's name as Windows lists it. Empty: Windows' default output, which may not be the device the game plays on. Your machine's names are in your RPT at mission start, after 'voice devices'."],
    ["JMSB - Voice (Built-in)", "Voice server (LiveKit)"],
    "",
    0,
    {[] call FUNC(applyDevices)}
] call CBA_fnc_addSetting;

// LOCAL VOICE over the server (no game VON, 2026-10-31): how far a voice
// carries to the people round the speaker. An operation value - a range.
[
    QGVAR(localRange), "SLIDER",
    ["Local voice range (m)", "How far your voice carries to the people round you: full beside you, fading to nothing at this range. Crew of one vehicle hear each other at full whatever the range."],
    ["JMSB - Voice (Built-in)", "Voice server (LiveKit)"],
    [LOCAL_RANGE_MIN, LOCAL_RANGE_MAX, LOCAL_RANGE_DEFAULT, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(secret), "EDITBOX",
    ["API secret", "Leave EMPTY: this setting is copied to every client, so anyone could sign himself in. Set JMSB_LIVEKIT_SECRET in the Arma server's environment (the server egg's variable) instead - the voice egg's LIVEKIT_API_SECRET."],
    ["JMSB - Voice (Built-in)", "Voice server (LiveKit)"],
    "",
    1
] call CBA_fnc_addSetting;
