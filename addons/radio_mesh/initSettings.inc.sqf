// CBA Settings [ADDON: jmfsb_radio_mesh]
//
// THE RADIOS ARE A MESH. A transmission that cannot reach a receiver directly
// is carried by other friendly radios on the same frequency - as many hops as
// it takes - each leg judged by ACRE's own propagation model, so terrain and
// antennas still count. Direct is always preferred when it is the stronger
// link; with no relay in reach the result is exactly ACRE's.
//
// OFF BY DEFAULT (user, 2026-09-05): a unit switches it on knowing what it
// changes. Off, the signal function still runs - ACRE's own point-to-point
// result, scaled by the jam level - so jamming is unaffected either way.

[
    QGVAR(enabled), "CHECKBOX",
    ["Enable mesh relaying", "OFF by default. On: friendly manpacks and vehicle racks on the same frequency relay transmissions that cannot reach a receiver directly. Off: ACRE's stock point-to-point signal, still scaled by jamming."],
    ["1st Joint Multi-Functional Strike Battalion", "Radio Mesh"],
    false,
    true
] call CBA_fnc_addSetting;

// WHICH RADIOS RELAY. Manpacks and vehicle racks (user, 2026-08-28; ACRE keeps
// its man packs - no man packs is game voice's rule, 2026-10-21) - the
// squad handheld is an end point, never a relay. Base class names, comma
// separated; a radio's base type is matched (ACRE_PRC152_ID_3 is a PRC152).
//
// THE 148 IS OFF THIS LIST because it is the team handset every man carries.
// Ninety-two riflemen acting as relays would mean team traffic hopping out of
// the team through the very men its low power is there to contain. Put it back
// only if it stops being the team radio.
[
    QGVAR(nodeRadios), "EDITBOX",
    ["Relay radios", "Comma-separated ACRE base radio classes that act as relay nodes when carried or racked. Anything can still be an end point."],
    ["1st Joint Multi-Functional Strike Battalion", "Radio Mesh"],
    "ACRE_PRC152,ACRE_PRC117F",
    true
] call CBA_fnc_addSetting;

// LOSS PER HOP, AND WHEN IT APPLIES. A relay transmitting under the threshold
// (default 1 W) costs this fraction of audio quality per hop; a relay at or
// above it repeats cleanly. Reception (dBm) is never penalised - a hop is a
// hop - only the quality of what comes through.
[
    QGVAR(hopLoss), "SLIDER",
    ["Loss per weak hop", "Fraction of signal quality lost for every relay hop made by a radio transmitting below the power threshold. 0 = lossless."],
    ["1st Joint Multi-Functional Strike Battalion", "Radio Mesh"],
    [0, 0.5, 0.1, 2],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(lossBelowMw), "SLIDER",
    ["Weak-hop threshold (mW)", "Relays transmitting below this power pay the loss per hop; at or above it they repeat cleanly. 1000 = 1 W."],
    ["1st Joint Multi-Functional Strike Battalion", "Radio Mesh"],
    [0, 10000, 1000, 0],
    true
] call CBA_fnc_addSetting;

// THE RELAY TABLE'S CADENCE. Radios, channels and sides change slowly; the
// table is rebuilt this often on each client. The signal function itself runs
// every time ACRE asks and only reads it.
[
    QGVAR(refresh), "SLIDER",
    ["Relay table refresh (s)", "Seconds between rebuilds of the list of relay-capable radios on this client."],
    ["1st Joint Multi-Functional Strike Battalion", "Radio Mesh"],
    [1, 30, 5, 0],
    true
] call CBA_fnc_addSetting;

// THE COST CEILING. The path search is quadratic in the relays it considers;
// only the nearest N (to the line between transmitter and receiver) are.
[
    QGVAR(maxNodes), "SLIDER",
    ["Relays considered per transmission", "Upper bound on relay radios examined for one transmission - the nearest to the transmitter/receiver line. Keeps the path search bounded on busy nets."],
    ["1st Joint Multi-Functional Strike Battalion", "Radio Mesh"],
    [2, 64, 16, 0],
    true
] call CBA_fnc_addSetting;
