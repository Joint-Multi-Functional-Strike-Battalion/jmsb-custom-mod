#include "script_component.hpp"
/*
 * Author: JMSB
 * What the four tiles currently say. One function so the band has one source
 * and the tile drawing stays about drawing.
 *
 * DRONES and JAM read jmfsb_hacking's scanner. That function already works out
 * drone count, bearing, range, jamming percentage and net state for the
 * hand-held device, and it caches - so asking it here is cheap and, more to the
 * point, the tile and the scanner can never disagree about how many drones
 * there are.
 *
 * With hacking absent, or with nothing in the player's pockets that can read a
 * spectrum, those two tiles say so rather than showing a confident zero.
 *
 * Arguments:
 * None
 *
 * THE STATE IS THE TILE'S WHOLE VOCABULARY. The design draws five and they are
 * not decoration: "alert" is the inverted accent block and means answer this
 * now, "warn" is the accent outline and means degraded but working, "stale"
 * means the feed is gone and the number on it cannot be trusted. A tile with no
 * source says "stale" rather than a confident zero, which is the difference
 * between no drones and no scanner.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * One entry per tile: [appId, kicker, qualifier, value, detail, state, icon] <ARRAY>
 * State is "rest", "alert", "warn" or "stale" <STRING>
 * Icon is a texture path, "" for none <STRING>
 *
 * Public: No
 */

private _out = [];

// --- DRONES and JAM, off the scanner -----------------------------------------
// TWO DIFFERENT THINGS, TWO DIFFERENT PAGES - the user's rule, in those
// words. The DRONES tile opens the drone page and speaks drones; the JAM tile
// opens the jamming page and speaks jamming. Channel and frequency were on
// the JAM tile's detail line - radio information - and are gone; the RADIO
// tile is the radio.
private _scan = [];
if (!isNil QEFUNC(hacking,scannerRead) && {[player] call EFUNC(hacking,hasScanner)}) then {
    _scan = [] call EFUNC(hacking,scannerRead);
};

if (_scan isEqualTo []) then {
    _out pushBack ["drones", "DRONES", "NO SET", "-", "NO SCANNER", "stale"];
    _out pushBack ["jam", "JAM", "NO SET", "-", "NO SCANNER", "stale"];
} else {
    _scan params ["_droneState", "_nearest", "_droneDir", "_jam"];

    // Slot 0 is a STATE - 0 clear / 1 warn (2 km) / 2 alert (1 km), per the
    // scanner's own contract - not a drone count. The tile printed the raw
    // number as its big value, so one drone inside a kilometre read
    // "DETECT 2". The word is the value now, like every consumer of this
    // read draws it. No qualifier: "DETECT" ran into the kicker, and the big
    // CLR / WARN / ALERT already says it (user, 2026-10-17).
    private _state = [0, _droneState] select (_droneState isEqualType 0);
    _out pushBack [
        "drones",
        "DRONES",
        "",
        ["CLR", "WARN", "ALERT"] param [_state, "CLR"],
        if (_state > 0) then {
            format ["BRG %1 - %2 KM", round _droneDir, (round (_nearest / 100)) / 10]
        } else {
            "AIR CLEAR"
        },
        ["rest", "alert"] select (_state > 0)
    ];

    private _jamPct = round (_jam * 100);
    _out pushBack [
        "jam",
        "JAM",
        "RF",
        format ["%1%2", _jamPct, "%"],
        ["SPECTRUM CLEAR", "SPECTRUM DEGRADED", "SPECTRUM SMOTHERED"] select ((parseNumber (_jamPct > 0)) + (parseNumber (_jamPct >= 75))),
        switch (true) do {
            case (_jamPct >= 50): {"alert"};
            case (_jamPct > 0): {"warn"};
            default {"rest"};
        }
    ];
};

// --- HACK, off the intrusion suite -------------------------------------------
// The tile is the ONLY way into the suite - the ACE entry lived on the cTab
// device and went with it. So it says whether it can be opened at all before it
// is pressed, because "nothing happened" is the worst answer a tile can give.
if (isNil QEFUNC(hacking,canHack)) then {
    _out pushBack ["hack", "HACK", "NO SUITE", "-", "SUITE NOT LOADED", "stale"];
} else {
    private _targets = count ([player, 50] call EFUNC(hacking,towersInRange));
    private _ready = [player] call EFUNC(hacking,canHack);

    private _detail = switch (true) do {
        case (!_ready): {"ISR OPERATOR ONLY"};
        case (_targets == 0): {"NOTHING IN RANGE"};
        default {"IN RANGE - PRESS TO OPEN"};
    };

    // Warn, not alert. A target in range is an opportunity; the accent block is
    // reserved for the things that are happening to you.
    _out pushBack [
        "hack",
        "HACK",
        ["LOCKED", "READY"] select _ready,
        [str _targets, "-"] select (!_ready),
        _detail,
        ["rest", "warn"] select (_ready && _targets > 0)
    ];
};

// --- WEATHER, off the engine -------------------------------------------------
private _cloud = overcast;
private _cover = switch (true) do {
    case (_cloud < 0.2): {"CLR"};
    case (_cloud < 0.45): {"FEW"};
    case (_cloud < 0.7): {"SCT"};
    case (_cloud < 0.9): {"BKN"};
    default {"OVC"};
};

date params ["", "", "", "_hour", "_minute"];

// The glyph is picked from the worst thing happening, not from the cloud cover:
// a storm over broken cloud is a storm. Day and night differ only where the
// artwork has a night form to differ with - a raincloud looks the same at 0200.
// The rain threshold is deliberately high. Arma runs a trace of rain under a
// heavy overcast most of the time, and at 0.05 the tile drew a raincloud beside
// the word OVC - a glyph disagreeing with the value right next to it. It has to
// be raining enough to notice before the glyph says so.
private _night = sunOrMoon < 0.5;
private _icon = switch (true) do {
    case (rain > 0.2 && {lightnings > 0.4}): {ICON_WX_STORM};
    case (rain > 0.2): {ICON_WX_RAIN};
    case (fog > 0.35): {ICON_WX_FOG};
    case (vectorMagnitude wind > 11): {ICON_WX_WIND};
    case (_cloud >= 0.7): {ICON_WX_CLOUD};
    case (_cloud >= 0.2): {[ICON_WX_FEW, ICON_WX_FEW_NIGHT] select _night};
    default {[ICON_WX_CLEAR, ICON_WX_CLEAR_NIGHT] select _night};
};

_out pushBack [
    "weather",
    "WEATHER",
    ["DRY", "RAIN"] select (rain > 0.1),
    _cover,
    format ["%1 AT %2 M/S - VIS %3 KM", round windDir, round (vectorMagnitude wind), (round (viewDistance / 100)) / 10],
    ["rest", "warn"] select (rain > 0.5),
    _icon
];

// --- TIMER, the alarms and the stopwatch -------------------------------------
// THE SOONEST ALARM WINS THE TILE. An armed alarm is a thing that will happen to
// you; a stopwatch is a thing you are doing. If any alarm is armed the band
// counts the nearest one down, and the stopwatch has the tile the rest of the
// time - both read off the same places the screen reads.
private _alarmList = missionNamespace getVariable [QEGVAR(hacking,alarms), []];
private _soonest = -1;
{
    private _left = (_x select 1) - CBA_missionTime;
    if (_soonest < 0 || _left < _soonest) then {_soonest = _left};
} forEach _alarmList;

([] call FUNC(timerState)) params ["_tSecs", "_tRunning", "_tDown", "_tExpired"];

if (_soonest >= 0) then {
    _tSecs = _soonest max 0;
    _tRunning = true;
    _tDown = true;
    _tExpired = false;
};

private _tHH = floor (_tSecs / 3600);
private _tClock = if (_tHH > 0) then {
    format ["%1:%2", _tHH, [floor ((_tSecs % 3600) / 60), 2] call CBA_fnc_formatNumber]
} else {
    format ["%1:%2", [floor (_tSecs / 60), 2] call CBA_fnc_formatNumber, [floor (_tSecs % 60), 2] call CBA_fnc_formatNumber]
};

_out pushBack [
    "timer",
    "TIMER",
    ["UP", ["DOWN", "ALARM"] select (_soonest >= 0)] select _tDown,
    _tClock,
    switch (true) do {
        case (_soonest >= 0): {format ["%1 ARMED - SOONEST", count _alarmList]};
        case (_tExpired): {"TIME - PRESS TO RESET"};
        case (_tRunning): {"RUNNING"};
        case (_tSecs > 0): {"HELD"};
        default {"READY - PRESS TO SET"};
    },
    switch (true) do {
        case (_tExpired): {"alert"};
        case (_tDown && _tRunning && _tSecs <= 60): {"warn"};
        case (_tRunning): {"warn"};
        default {"rest"};
    }
];

// --- RADIO, off game voice ------------------------------------------------------
// The active net and its state, as jmfsb_voice reports them (netState: [net,
// name, kind, active, muted, ear, reachable, talkers]). Without jmfsb_voice
// the tile has no source and is drawn stale so it reads as one. An active net
// that reaches nobody is "warn": degraded, not gone.
if (isNil QEFUNC(voice,netState)) then {
    _out pushBack ["radio", "RADIO", "NO SRC", "----", "NO VOICE", "stale"];
} else {
    private _nets = [] call EFUNC(voice,netState);
    private _i = _nets findIf {_x param [3, false]};
    if (_i < 0) then {
        _out pushBack ["radio", "RADIO", "NO NET", "----", format ["%1 NETS", count _nets], "warn"];
    } else {
        (_nets select _i) params [["_netId", ""], ["_name", ""], ["_kind", ""], "", ["_muted", false], "", ["_reach", false], ["_talkers", []]];
        private _detail = switch (true) do {
            case (!_reach): {"NO LINK"};
            case (_muted): {"MUTED"};
            case (_talkers isNotEqualTo []): {format ["%1 TALKING", count _talkers]};
            default {"QUIET"};
        };
        _out pushBack ["radio", "RADIO", toUpper _kind, [_name, _netId] select (_name isEqualTo ""), _detail, ["warn", "rest"] select _reach];
    };
};

// --- tiles other addons add ---------------------------------------------------
// Each provider answers its own tiles, or none - jmfsb_devices' VEHICLE tile
// answers only while the vehicle tablet is up. They pass the role gate below
// like every other tile, except the ids a provider has listed in tileUngated:
// a tile its own device already gates, which no role's tiles[] names.
{
    _out append ([] call _y);
} forEach (missionNamespace getVariable [QGVAR(tileProviders), createHashMap]);

// --- the role gate -----------------------------------------------------------
// THE ONLY PLACE TILES COME FROM, so it is the only place access has to be
// enforced. A tile the man's role does not carry is removed here rather than
// hidden later: it is not drawn, it takes no space in the band, and the app
// behind it cannot be opened, because clicking a tile is the only way in.
//
// Missions that declare no tiles[] on any role are not gated at all - see
// FUNC(roleTiles).
([player] call FUNC(roleTiles)) params ["_gated", "_allowed"];

if (_gated) then {
    private _ungated = missionNamespace getVariable [QGVAR(tileUngated), []];
    _out = _out select {(_x # 0) in _allowed || {(_x # 0) in _ungated}};
};

// --- band order --------------------------------------------------------------
// LEFT TO RIGHT, DECLARED HERE RATHER THAN LEFT TO THE PUSH ORDER ABOVE. The
// tiles are built in branches - a stub when the scanner is absent, the real
// reading when it is there, nothing at all when a suite is not loaded - so the
// order they happen to be pushed in is not a decision anybody made. This is.
//
// THE TWO THAT ACT RATHER THAN REPORT SIT ON THE RIGHT: SUPPORT calls something
// in and HACK does something to something, while the other five only tell you
// what is true. Reading tiles stay left where the eye starts.
//
// A tile not named here sorts to the end rather than to the front, so adding one
// and forgetting this list puts it in the wrong place instead of at the head of
// the band where it would push everything else along.
// --- INTEL, the files a hack has recovered ----------------------------------
// The side's own count, off the store EFUNC(hacking,productPackage) broadcasts.
// It reads NO FILES rather than 0 because a zero on a tile looks like a thing
// that failed, and nothing has failed - nobody has hacked anything yet.
// `player`, as everywhere else here: ACE is optional, and without it ACE_player
// is nil and the whole band throws on this line.
private _intel = (missionNamespace getVariable [QEGVAR(hacking,packageIntel), createHashMap])
    getOrDefault [str (side group player), []];
private _folders = [];
{ _folders pushBackUnique (_x # 0) } forEach _intel;

_out pushBack [
    "intel",
    "INTEL",
    ["NO FILES", "FILES"] select (_intel isNotEqualTo []),
    str count _intel,
    [
        "NOTHING RECOVERED",
        format ["%1 FOLDER%2 - PRESS TO READ", count _folders, ["", "S"] select (count _folders > 1)]
    ] select (_intel isNotEqualTo []),
    ["stale", "rest"] select (_intel isNotEqualTo [])
];

// --- SUPPORT, over the support core ----------------------------------------
// NO CORE, NO TILE. The app is not registered without it either - a live
// tile reading NO LINK for a system that is not installed is a permanent
// apology, and the band is only six wide.
//
// ONE COUNT, ANY NUMBER OF BACK ENDS. EFUNC(support,assets) merges every
// registered provider's rows - ALiVE's ATO and NEO assets, jmfsb's CAS drones,
// support_fires and support_air - so this does not care which of them is present.
if (!isNil QEFUNC(support,assets)) then {
    private _support = call EFUNC(support,assets);
    private _idle = {(_x param [4, ""]) isEqualTo "idle"} count _support;
    _out pushBack [
        "support",
        "SUPPORT",
        ["NO LINK", "AIR"] select (_support isNotEqualTo []),
        str count _support,
        ["CS LINK NOT WIRED", format ["%1 IDLE - PRESS TO TASK", _idle]] select (_support isNotEqualTo []),
        ["stale", "rest"] select (_support isNotEqualTo [])
    ];
};

// --- PAC, the unit ------------------------------------------------------------
// Structure hash, current OPORD, players on, op window - the handoff's own list
// for the tile. Read off the summary the server publishes rather than the
// roster, so the band never walks a player list. Guarded on the addon: a mod
// built without jmfsb_pac has no tile, the same rule as the map tools strip.
if (!isNil "jmfsb_pac_summary") then {
    private _pac = jmfsb_pac_summary;
    private _opord = _pac getOrDefault ["opord", ""];
    // window is the id of the op window that is on ("" for none) since the
    // attendance work; it was a bool before. Read it as "is one on".
    private _window = _pac getOrDefault ["window", ""];
    private _open = _window isEqualType "" && _window isNotEqualTo "";
    private _hash = _pac getOrDefault ["hash", 0];

    _out pushBack [
        "pac",
        "PAC",
        ["NO OP", "OP OPEN"] select _open,
        str (_pac getOrDefault ["players", 0]),
        format ["%1 - %2", ["NO OPORD", toUpper _opord] select (_opord isNotEqualTo ""), _hash],
        ["rest", "warn"] select _open
    ];
};

private _order = ["vehicle", "drones", "jam", "weather", "timer", "radio", "medic", "hack", "intel", "support", "pac"];

private _ranked = _out apply {
    private _i = _order find (_x # 0);
    [[_i, 999] select (_i < 0), _x]
};
_ranked sort true;

_ranked apply {_x # 1}
