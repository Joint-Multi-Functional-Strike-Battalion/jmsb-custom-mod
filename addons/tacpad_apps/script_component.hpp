#define COMPONENT tacpad_apps
#define COMPONENT_BEAUTIFIED Tacpad Apps
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#include "\z\jmfsb\addons\main\script_macros.hpp"

// Geometry and idcs only. The shell's own script_component.hpp is deliberately
// NOT included: it defines COMPONENT, which would redirect every PREP in this
// addon at the shell's function folder.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// The tile module from the design: 176x98 at 1600x900, carried over as
// fractions of the safe zone so it holds its proportions at any resolution.
// 0.086, not the design's 0.092. Six tiles, five gaps and two margins have to
// fit between the squad rail and the reader column - 0.562 of the safe zone -
// and at 0.092 they came to 0.585, which put the sixth tile through the reader's
// edge and made the band drop it entirely. The arithmetic is done with the
// panel's own borders counted, because the sixth tile is the one that pays for
// any rounding: 6 x 0.086 + 5 x 0.005 + margins leaves a thousandth spare.
// Trimmed from 0.086 when SUPPORT joined the band - compressed a little,
// with the band itself grown leftward for the rest of the room.
#define TILE_W 0.082
#define TILE_H 0.078
#define TILE_GAP 0.005
// THE TILE QUALIFIERS (notes, 2026-10-30): the JAM tile names the domain hit
// - the jamming addon's three, by the words the tile shows; the MSG tile the
// highest unread precedence, these being the raised ones under FLASH.
#define JAM_DOMAINS [["DATA", "data"], ["RADIO", "radio"], ["GPS", "gps"]]
#define MSG_RAISED_PRIORITIES ["PRIORITY", "MEDIUM"]

// TILE STATE COLOURS (user, 2026-10-30, the TAC//APP mockup: "I like the
// colours around the tiles based on status"): the outline, a tint over the
// ground, the value and the qualifier's badge all in the state's colour -
// amber warn, green ok. Fixed, never themed, like the swatches below. The
// tint's and the badge's alpha. ALERT IS THE ACCENT, not a fixed red (review
// 2026-11-01, R4): the inverted accent block, FUNC(tileLive).
#define TILE_AMBER [0.85, 0.65, 0.15, 1]
#define TILE_GREEN [0.25, 0.75, 0.45, 1]
#define TILE_TINT_ALPHA 0.12
#define TILE_BADGE_ALPHA 0.9
// The band's dim ink: stale text and a dead page arrow.
#define TILE_DIM_ALPHA 0.45

// THE LIVE APPS' QUIETER INK (FUNC(appTimer), FUNC(appScanner)): the ink at
// these alphas for labels and for an empty line. An alarm's countdown goes
// red inside TIMER_RED_SECS and amber (TILE_AMBER) inside TIMER_AMBER_SECS.
// The scanner calls jamming CONTESTED from SCANNER_JAM_CONTESTED up and shows
// the newest SCANNER_ALERTS entries of the alert log.
#define LIVE_MUTE_ALPHA 0.62
#define LIVE_DIM_ALPHA 0.42
#define TIMER_RED_SECS 30
#define TIMER_AMBER_SECS 120
// TIMER, THE OLD TIMER IN A CLEANER LAYOUT (user, 2026-11-01: "old timer but
// better visual design" - the IN / AT rework of DESIGN_TABLET_REVIEW 3.7 is
// reverted). The quick keys in minutes, each ARMING on the press; the CUSTOM
// delay's and the ALARM AT time's steps, [label, minutes]; the delay's floor
// and ceiling and the day (s). The page: the frame's width (host fractions),
// the label column's share of the body, the DEL key's share, the value size
// (never under the tile detail size, R1) and the air round a section rule in
// pads.
#define TIMER_QUICK [1, 2, 3, 5, 10]
#define TIMER_CUSTOM_STEPS [["-10", -10], ["-1", -1], ["+1", 1], ["+10", 10], ["+60", 60]]
#define TIMER_AT_STEPS [["-1H", -60], ["-10", -10], ["-1", -1], ["+1", 1], ["+10", 10], ["+1H", 60]]
#define TIMER_DELAY_MIN 60
#define TIMER_DELAY_MAX 86400
#define TIMER_DAY_SECS 86400
#define TIMER_APP_W 0.5
#define TIMER_LABEL_W 0.26
#define TIMER_DEL_W 0.2
#define TIMER_VALUE_TEXT (KV_TEXT max TEXT_TITLE)
#define TIMER_SECTION_AIR 3
#define SCANNER_JAM_CONTESTED 0.75
#define SCANNER_ALERTS 4

// The server's machine, for remoteExec to it (review S7).
#define SERVER_OWNER 2

// Squad health swatches. Hue IS the data here and nowhere else in the suite -
// it is the one place allowed to break the near-mono rule, and only because
// "amber" and "black" mean something a shade of the accent cannot say.
#define HEALTH_OK [0.20, 0.55, 0.25, 1]
#define HEALTH_WIA [0.85, 0.68, 0.15, 1]
#define HEALTH_UNCON [0.55, 0.55, 0.55, 1]
#define HEALTH_KIA [0.10, 0.10, 0.10, 1]

// THE SQUAD ROSTER'S MEMBER MARK (FUNC(squadIcon)): jmfsb_bft's map member
// icon on a row - its outline and body textures, the fire-team colours and
// whether the number on each is dark, exactly as jmfsb_bft_fnc_drawMembers
// draws them - and how faint a man who is down or dead is drawn.
#define SQUAD_ICON_BODY QPATHTOEF(bft,data\member_body_ca.paa)
#define SQUAD_ICON_OUTLINE QPATHTOEF(bft,data\member_outline_ca.paa)
#define SQUAD_ICON_OUTLINE_RGBA [0.13, 0.12, 0.11, 1]
#define SQUAD_ICON_TEAMS [["MAIN", [[1, 1, 1, 1], true]], ["RED", [[0.90, 0.22, 0.21, 1], false]], ["GREEN", [[0.26, 0.63, 0.28, 1], false]], ["BLUE", [[0.12, 0.53, 0.90, 1], false]], ["YELLOW", [[0.99, 0.85, 0.21, 1], true]]]
#define SQUAD_ICON_DARK_TEXT [0.13, 0.12, 0.11]
#define SQUAD_ICON_LIGHT_TEXT [1, 1, 1]
#define SQUAD_ICON_DOWN_ALPHA 0.5
// The icon's height as a share of the row it sits in.
#define SQUAD_ICON_ROW_K 0.8
// THE MEMBER PAGE (FUNC(appSquadMember)): ACE's full blood volume in litres
// (jmfsb_medic's BLOOD_VOLUME_FULL), the ammunition share that reads low (the
// same 35 the STRENGTH tile's AMMO AVG goes hot under), and how many patient
// wound parts the WOUNDS line names before it says "+N".
#define SQUAD_BLOOD_FULL 6
#define SQUAD_AMMO_LOW 35
#define SQUAD_WOUND_PARTS 2
// DIST's bearing: whole degrees, 360 folded to 000, three figures.
#define SQUAD_BEARING_FULL 360
#define SQUAD_BEARING_DIGITS 3

// The state glyphs that go with them, carried over from the archived cTab
// device suite. See data\medical\NOTICE.md - they are MIRA Vehicle Medical's,
// under Apache 2.0.
#define ICON_OK QPATHTOF(data\medical\ok_green.paa)
#define ICON_WIA QPATHTOF(data\medical\bleeding_red.paa)
#define ICON_UNCON QPATHTOF(data\medical\unconscious_white.paa)
#define ICON_KIA QPATHTOF(data\medical\dead.paa)

// Weather glyphs. Alpha-only silhouettes, so they tint to whatever the scheme's
// ink is rather than carrying the source artwork's own blue and yellow onto a
// near-mono screen - see data\weather\NOTICE.md.
#define ICON_WX_CLEAR QPATHTOF(data\weather\clear.paa)
#define ICON_WX_CLEAR_NIGHT QPATHTOF(data\weather\clear_night.paa)
#define ICON_WX_FEW QPATHTOF(data\weather\few.paa)
#define ICON_WX_FEW_NIGHT QPATHTOF(data\weather\few_night.paa)
#define ICON_WX_CLOUD QPATHTOF(data\weather\cloud.paa)
#define ICON_WX_RAIN QPATHTOF(data\weather\rain.paa)
#define ICON_WX_STORM QPATHTOF(data\weather\storm.paa)
#define ICON_WX_SNOW QPATHTOF(data\weather\snow.paa)
#define ICON_WX_FOG QPATHTOF(data\weather\fog.paa)
#define ICON_WX_WIND QPATHTOF(data\weather\wind.paa)

// THE WEATHER PAGE (review 2026-11-01, DESIGN_TABLET_REVIEW 3.6): two columns
// of FUNC(kvRow) - conditions on the left, light on the right - in a frame
// this wide (safe-zone fractions; a device host gives it the whole app area).
// The value column that was WX_VALUE_AT is FUNC(kvRow)'s measured one now.
// The hero block is this many rows tall at the least, its word this share of
// it; the page shrinks by one factor when the screen runs out, never past the
// share of the host it may take.
#define WX_APP_W 0.6
#define WX_COLUMNS 2
#define WX_HERO_ROWS 3
#define WX_HERO_WORD 0.62
#define WX_HOST_MAX 0.92
// THE VERDICT THRESHOLDS, one set for NOW and FORECAST so the two cannot judge
// the same sky differently: rotary / CAS marginal over this overcast, fog or
// wind (m/s); thermal degraded over this rain or fog.
#define WX_AIR_OVERCAST 0.75
#define WX_AIR_FOG 0.4
#define WX_AIR_WIND 12
#define WX_THERMAL_RAIN 0.1
#define WX_THERMAL_FOG 0.3
// FORECAST (DESIGN_TABLET_APPS.md WEATHER): the window the design asks for,
// in hours. The engine only forecasts toward its next change, so a change
// further out than this is named as past the window, never tabled hourly.
#define WX_FORECAST_HOURS 8
#define WX_SECS_PER_HOUR 3600
#define WX_HOURS_PER_DAY 24

// The three app glyphs. Base-game files rather than shipped ones - they are
// single-colour marks the suite tints like any other, so there is nothing to be
// gained by carrying a copy of them.
//
// EVERY ONE OF THESE IS A REAL FILE, checked against the unpacked base game.
// The UAV glyph was `b_uav_ca.paa`, which does not exist anywhere in A3 - the
// DRONES tile drew nothing and logged "Picture ... not found" once per mission.
// `uavconncetion_ca.paa` is spelled that way by Bohemia and is correct.
#define ICON_UAV "\A3\ui_f\data\gui\cfg\hints\uavbasic_ca.paa"
#define ICON_JAM "\A3\ui_f\data\gui\cfg\hints\uavconncetion_ca.paa"
#define ICON_RADIO "\A3\ui_f\data\igui\cfg\simpleTasks\types\radio_ca.paa"

// How many roster rows and traffic rows a docked panel draws before it stops.
// Both have an OPEN FULL behind them, so this is about what fits in a rail
// without becoming a wall of text.
#define ROSTER_MAX 16
#define TRAFFIC_MAX 12

// FUNC(row)'s value column, as a share of the row's width. ROW_VALUE_RIGHT is
// no column: the value right-aligned at the row's far edge, as every list in
// the suite has always drawn it. A caller that sets a column gets the value
// left-aligned from there, a short reach past the label instead of a screen
// away from it.
#define ROW_VALUE_RIGHT 0

// THE KEY/VALUE LIST (FUNC(kvRow); review 2026-11-01, DESIGN_TABLET_REVIEW 2.4,
// decisions R1 and R2). KV_TEXT is the tile band's detail size - values and
// body text are never drawn smaller (R1). A row is that line plus KV_AIR_PX,
// never less than the list row. The label column is its longest label plus
// KV_GAP_PX and at most KV_LABEL_MAX of a column; columns are KV_GUTTER_PX
// apart, and an area left to choose gets one per KV_COLUMN_W of the host, up
// to KV_COLUMNS_MAX.
#define KV_TEXT ([TEXT_BODY, APP_TEXT_UP_PX] call EFUNC(tacpad,textPx))
#define KV_AIR_PX 8
#define KV_ROW_H ((([KV_TEXT] call EFUNC(tacpad,textH)) + KV_AIR_PX * pixelH) max ROW_H_SCREEN)
#define KV_GAP_PX 10
#define KV_LABEL_MAX 0.6
#define KV_GUTTER_PX 24
#define KV_COLUMN_W 0.3
#define KV_COLUMNS_MAX 3

// THE SETTINGS APP'S ROWS (FUNC(appSettings)): how much of the pane a stepper's
// value takes - wide enough for a list's choice by name, not only a number -
// and the word a row the server or mission forces carries instead of controls.
#define SETTINGS_STEP_VALUE_W 0.3
#define SETTINGS_LOCKED "LOCKED"
// The settings rows read larger than the rest of the suite (user, 2026-10-24:
// "in settings larger fonts"): text and row height both scaled.
#define SETTINGS_TEXT_K 1.2
#define SETTINGS_ROW_K 1.25
#define SETTINGS_TEXT (TEXT_TITLE * SETTINGS_TEXT_K)
// Notification time on screen (jmfsb_notify_duration), stepped from SETTINGS >
// NETS & ALERTS within the notify addon's own slider range.
#define NOTIFY_DURATION_MIN 2
#define NOTIFY_DURATION_MAX 30
// SETTINGS > DISPLAY: the existing settings' own choices, in their own order -
// jmfsb_tacpad_displayMode's and jmfsb_notify_corner's.
#define DISPLAY_MODE_IDS ["native", "tablet"]
#define NOTIFY_CORNER_IDS [0, 1, 2, 3]
#define NOTIFY_CORNER_NAMES ["TOP LEFT", "TOP RIGHT", "BOTTOM LEFT", "BOTTOM RIGHT"]
// LIVE TILES, per player (user, 2026-10-24: "turn on and off live tiles in
// settings and assign a slot"): every tile the band can carry, in its default
// order, and the setting that holds "id:slot" / "id:off" pairs. A tile with no
// entry is AUTO - shown, in default order after the placed ones.
// No SUPPORT tile (user, 2026-11-01: "thought we were removing this").
#define TILE_CHOICES [["vehicle", "VEHICLE"], ["drones", "DRONES"], ["jam", "JAM"], ["weather", "WEATHER"], ["timer", "TIMER"], ["radio", "RADIO"], ["msg", "MSG"], ["arty", "ARTY"], ["medic", "MEDIC"], ["hack", "HACK"], ["intel", "INTEL"], ["pac", "PAC"], [LOG_APP, "LOG"]]
// THE TILES THE TABLET DOES NOT CARRY (user, 2026-11-01): PAC is a button on
// the device bar between MENU and ESC CLOSES (jmfsb_devices_fnc_tabletBar).
// The map's band (Display mode Native) keeps the tile - it has no bar.
#define TILES_NATIVE_ONLY ["pac"]

// ARTY - the artillery team's calculator and tile (user, 2026-10-25). ACE's
// mil is 6400 to the circle (its DEGTOMILS); the standard atmosphere and air
// friction are ACE's defaults (ace_artillerytables). A gun is the piece he is
// in or the nearest within the player's gun range setting; a radar fix younger
// than ARTY_FIX_HOT seconds puts the tile on alert. MRSI offers up to
// ARTY_MRSI_MAX solutions; the marker list holds the nearest ARTY_MARKERS_MAX.
#define ARTY_MILS_PER_DEG 17.7777778
#define ARTY_STD_TEMP 15
#define ARTY_STD_DENSITY 1.225
#define ARTY_ACE_DEFAULT_AF -0.00006
#define ARTY_G 9.8066
#define ARTY_FIX_HOT 120
#define ARTY_MRSI_MAX 3
#define ARTY_MARKERS_MAX 20
#define ARTY_APP_W 0.62
#define ARTY_APP_H 0.66
#define ARTY_ROW_K 1.2
// TILES PER PAGE OF THE BAND (user, 2026-10-24: "tile pos 1-10"; 2026-10-30:
// "add a 11th through 16th slot that you get to using the left right arrows
// ... increase the slot count with every new app"): every tile has a slot,
// the band shows this many a row, and arrows at its ends turn the page.
#define TILE_SLOTS 10
// The page arrows: a column this wide at each end of the band, their glyphs.
#define TILE_ARROW_PX 14
#define TILE_ARROW_LEFT "<"
#define TILE_ARROW_RIGHT ">"
// The qualifier's badge (user, 2026-10-30: "scrunched up text"): its word is
// CHIP_SIZE_K of the tile's small text, sized at the monospace's own advance
// (wider than the chips' tracked estimate, so it never wraps), and never more
// than this share of the tile - the kicker takes what is left.
// (0.66 still wrapped a two-letter badge - "R / F", "U / P" - in the first
// run, 2026-10-31: the structured text keeps a margin each side)
#define TILE_BADGE_GLYPH 0.8
#define TILE_BADGE_MAX_K 0.5
// THE KICKER'S FLOOR (review 2026-11-01, item 2.7: "DRON"): the badge never
// takes the kicker below this many glyphs - DRONES whole. A tracked kicker
// glyph and the space after it are about this much of the font height.
#define TILE_KICKER_MIN_GLYPHS 6
#define TILE_KICKER_GLYPH 0.8
// THE MENU APP (user, 2026-10-30: "add a menu icon to get to each app and
// settings"; the tablet bar's MENU): every app the tiles know and SETTINGS,
// one row each. Its frame, in safe-zone fractions.
// The app with no tile on the tablet (user, 2026-11-01) keeps its MENU row:
// TAC//PAC, which the bar's PAC button also opens. TAC//SUPPORT is gone
// (2026-11-01: support is called by message, DESIGN_SUPPORT_MESSAGING).
#define MENU_APPS_NO_TILE [["pac", "PAC"]]
#define MENU_APP "menu"
#define MENU_APP_W 0.3
#define MENU_APP_H_MAX 0.8
#define MENU_SETTINGS_APP "settings"
#define MENU_SETTINGS_NAME "SETTINGS"
// The settings dropdown: its share of the row, and its type against the row height.
#define SETTINGS_COMBO_W 0.32
#define SETTINGS_COMBO_FONT_K 0.62
#define TILE_SLOT_AUTO -1
#define TILE_SLOT_OFF 0
#define TILE_SLOT_DEFAULT_BASE 100
// The PAC tile's detail reads larger (user, 2026-10-24); its kicker is the
// band's size like every tile's (review 2026-11-01, item 2.7).
#define TILE_TEXT_K_PAC 1.35
// Unread traffic of these priorities makes the MSG tile an alert.
#define MSG_URGENT_PRIORITIES ["FLASH", "IMMEDIATE", "HIGH"]
// THE LOG APP (user, 2026-11-09: "add back in the logs app"): its id, and the
// LOG tile - the notices kept (jmfsb_notify's history), the newest one's
// title and text on the detail line, the qualifier the count of the last
// LOG_RECENT_S seconds.
#define LOG_APP "log"
#define LOG_RECENT_S 300
#define LOG_DETAIL_FORMAT "%1 - %2"
#define LOG_NONE "NO NOTICES"

// ============================================ RADIO / DRONES / HACK pages ===
// docs/DESIGN_TABLET_APPS.md, the RADIO, DRONES and HACK boards. The three
// apps share the panel vocabulary below (FUNC(appPagePanel), FUNC(appPageTabs),
// FUNC(appPageButton), FUNC(appPageBar)); each keeps its own numbers here.

// The board: nearly the whole map area, as the design draws it - panels side
// by side over the map, not a dialog in the middle of it. Fractions of the host.
#define PAGE_W 0.94
#define PAGE_H 0.86
// The left panel's share of the board's width (CHANNELS, FLEET, NODES).
#define PAGE_SPLIT_RADIO 0.64
#define PAGE_SPLIT_DRONES 0.36
#define PAGE_SPLIT_HACK 0.58
// The top-right panel's share of the right column's height (RADIO SET, ACTION).
#define PAGE_SPLIT_RIGHT 0.56

// Quality bars: green at or above GOOD, yellow at or above FAIR, accent below.
// A link-quality number is RF's 0..1 (jmfsb_rf_fnc_quality); -1 is RF's
// "does not know", drawn as an empty bar with a dash.
#define QUALITY_GOOD 0.7
#define QUALITY_FAIR 0.4
#define QUALITY_UNKNOWN -1
#define PERCENT 100

// RADIO (docs/DESIGN_VOICE.md, "Tablet RADIO app"). Game voice (VON) through
// jmfsb_voice's API; this board reads it and never names a radio mod.
// RF's own data net, which every set holds - DRONES reads it too.
#define RADIO_NET_DATA "DATA"
// The tabs of the RADIO board, and how often the open board looks for change.
#define RADIO_TABS [["nets", "NETS"], ["calls", "CALLS"], ["manage", "MANAGE"]]
#define RADIO_REFRESH 1
// The voice API's ear words, in the order the L / B / R segments are drawn.
#define RADIO_EARS ["L", "B", "R"]
// The handheld's battery on NETS (user, 2026-10-30): read in the accent and
// the swap button in the alarm style at this share of full and under.
#define RADIO_BATTERY_LOW 0.2
// A call's states (jmfsb_voice_fnc_calls) and priorities.
#define CALL_RINGING "ringing"
#define CALL_LIVE "live"
#define CALL_OUTGOING "outgoing"
#define CALL_ROUTINE "ROUTINE"
#define CALL_FLASH "FLASH"
// A call holds at most this many people, under every system (DESIGN_VOICE.md
// "Calls"); how many calls at once is the voice system's (CALL_SLOTS below).
#define CALL_SIZE_MAX 8
// What jmfsb_voice_callState's states say to a player (its README: "warning",
// "ended" and the failure reasons), and how long the line stays up (s).
#define CALL_STATE_WORDS [["warning", "PRIORITY WARNING - A FLASH CALL IS TAKING THIS SLOT"], ["ended", "CALL ENDED"], ["noRoute", "NO ROUTE - CALL BACK IS AVAILABLE"], ["busy", "BUSY - CALL BACK IS AVAILABLE"], ["noAnswer", "NO ANSWER - CALL BACK IS AVAILABLE"], ["declined", "DECLINED"], ["bumped", "BUMPED BY A FLASH CALL"], ["dropped", "DROPPED - NO ROUTE"], ["refused", "NOBODY IN REACH ON DATA"], ["notOwner", "ONLY THE CALL'S OWNER CAN ADD PEOPLE"]]
#define CALL_STATE_HOLD 8
// THE ECHO TEST's states, as jmfsb_adapter_livekit_fnc_echoState gives them
// ("" no voice extension: no row on CONTACTS).
#define ECHO_IDLE "idle"
#define ECHO_JOINING "joining"
#define ECHO_LIVE "live"

// THE CALL'S PICTURE (FUNC(callFeed)): no video is sent - each viewer's machine
// renders a camera on the other man. The sender picks what his camera sends
// (public on him as GVAR(callCam)): FACE, in front of his face looking back
// at him, or VIEW, at his eyes looking where he looks. The surface name and
// resolution, the default distances from his eyes (m) and how far either way
// the settings move them, the field of view of each, how
// often who is shown and what he sends are looked at again (s).
#define CALL_FEED_RTT QGVAR(callFeed)
#define CALL_FEED_RES 512
#define CALL_CAM_FACE "face"
#define CALL_CAM_VIEW "view"
#define CALL_CAM_FACE_DIST 0.8
#define CALL_CAM_VIEW_AHEAD 0.15
#define CALL_CAM_NUDGE 0.2
#define CALL_CAM_FACE_FOV 0.5
#define CALL_CAM_VIEW_FOV 0.75
#define CALL_FEED_TICK 0.25
// VON's channel ids (DESIGN_VOICE.md, "Channels"): the fixed ones by name, and
// custom channel n is id CUSTOM_BASE + n - 1. C2 and A2G hold the first two
// custom channels for good; CALL 1-8 the other eight.
#define VON_CHANNEL_NAMES [[0, "Global"], [1, "Side"], [2, "Command"], [3, "Group"], [4, "Vehicle"], [5, "Direct"]]
#define VON_CUSTOM_BASE 6
#define VON_CUSTOM_COUNT 10
#define VON_FIXED_CUSTOM [["C2", 1], ["A2G", 2]]
// The custom channels that can hold a call: the strip on CALLS draws these
// alone, C2 and A2G apart as the fixed nets (tablet review 2026-11-01, R8).
#define CALL_SLOTS (VON_CUSTOM_COUNT - count VON_FIXED_CUSTOM)
// NO LIMIT TO THE NUMBER OF CALLS ON THE VOICE SERVER (user, 2026-11-01: "on
// the radio calls tab there should be no limit to the # of calls"). The strip
// and its count are game VON's (jmfsb_voice_system "von"); on the voice
// server (Mumble or LiveKit) CALLS lists the calls there are, as many as
// there are, in a list that scrolls - each row this many text lines high.
#define VOICE_SYSTEM_VON "von"
#define CALLS_ROW_LINES 1.3
// The voice API's net kinds a device row never shows: direct voice is not a net.
#define VOICE_KIND_DIRECT "direct"
#define VOICE_KIND_CALL "call"
#define VOICE_KIND_TEAM "team"
// jmfsb_voice_system "none" (jmfsb_voice_active false): the server's voice
// cannot run on this machine - every RADIO tab says this instead.
#define TEXT_VOICE_UNAVAILABLE "VOICE UNAVAILABLE"
// The group adds (DESIGN_VOICE.md, "Add people"): [id, button, contact tag];
// "team" is the player's own group and carries no tag.
#define RADIO_GROUPS [["team", "+ MY TEAM", ""], ["sl", "+ SQUAD LEADERS", "SL"], ["rto", "+ RTOs", "RTO"], ["medic", "+ MEDICS", "MEDIC"], ["hq", "+ HQ", "HQ"]]
// Who may do what on MANAGE (DESIGN_VOICE.md, the permission table): the
// action and the lowest of TL < SL < RTO < ADMIN that may. RADIO_ROLES is
// that order; FUNC(radioRole) answers the player's place in it.
#define RADIO_ROLES ["", "TL", "SL", "RTO", "ADMIN"]
// The RTO console is a player job (user, 2026-10-20): the RTO column holds
// every MANAGE action but the export of the plan to the mission config.
// Custom nets are the RTO's (user, 2026-10-22: "allow rtos to add custom
// channels") - the row that was "temp net, patch" at SL.
#define RADIO_RIGHTS [["own nets, members", "TL"], ["add / remove (own team)", "TL"], ["custom nets", "RTO"], ["rekey, PACE, EMCON", "SL"], ["C2 / A2G, calls, bump", "RTO"], ["signal plan load, reset", "RTO"], ["signal plan export", "ADMIN"]]
// CUSTOM NETS ON MANAGE (user, 2026-10-22: "add an rto skill or trait, and on
// the radio app allow rtos to add custom channels"): an RTO's or admin's own
// voice net, made, peopled and removed on MANAGE through the voice API
// (jmfsb_voice_fnc_customList / netAdd / netMembers / netRemove). The voice
// API's kind for one; its name's longest - the voice addon's CUSTOM_NAME_MAX:
// the id IS the name, and the device rows' chip shows it; and what the board
// reads for the voice addon's cap on them at once (jmfsb_voice_customNetsMax:
// each takes a VON custom channel for the rest of the mission) when that
// setting is not declared.
#define VOICE_KIND_CUSTOM "custom"
#define CUSTOM_NAME_MAX 10
#define CUSTOM_NETS_MAX_DEFAULT 2
// The draft of a custom net's members on MANAGE, [net id, squads, uids] in
// uiNamespace (QGVAR(radioMembersDraft)) - the columns a tick changes.
#define DRAFT_COL_SQUADS 1
#define DRAFT_COL_UIDS 2
// A tick square's side as a share of its row (FUNC(radioTick)), a tick chip's
// width as a share of its panel, and how many rows of chips a panel gives the
// squads before it says "+N more" - the people under them need the rest.
#define TICK_BOX_K 0.55
#define CUSTOM_CHIP_K 0.17
#define CUSTOM_CHIP_ROWS_MAX 2
// How many RTO nets the NETS panel lists before "+N more": the ADD NET form
// below them needs the rest of the panel.
#define CUSTOM_LIST_MAX 3
// The draft name of a new net (QGVAR(radioNewName)) and its ticked squads
// (QGVAR(radioNewSquads)) live in uiNamespace so a redraw keeps them.
// Recent contacts the board and the walking view's quick add offer, newest first.
#define RADIO_RECENT_MAX 8
// The player's leader words that place him (FUNC(radioRole)), from his slot's
// role. RTO is not here: it is the voice addon's one RTO test
// (jmfsb_voice_fnc_isRto).
#define RADIO_ROLE_WORDS [["SL", ["SL", "SQUAD LEADER", "PL", "PSG", "PLATOON"]], ["TL", ["TL", "FTL", "TEAM LEADER"]]]
// THE WHO CAN TABLE'S MARKS (tablet review 2026-11-01, 3.10): a role that may
// is an ink square this many screen pixels a side - the reader roster's and
// the support checklist's "done" - and one that may not is a dash. The check
// mark (U+2713) it drew is not in the tacpad's fonts, so every cell was blank.
#define WHO_CAN_MARK_PX 7
#define WHO_CAN_NO "-"
// The separator a contact's tags follow, written as a number so the file stays ASCII.
#define MIDDOT_TEXT (toString [183])
#define SECONDS_PER_MINUTE 60
// SOUNDS (DESIGN_VOICE.md, "Sounds": radio beeps on/off, call beeps on/off, one
// beep volume, pitch per net, static by quality): [label, the voice addon's
// CBA setting, "bool" or "slider"]. A setting no loaded addon declares is not
// drawn, rather than a switch that switches nothing (tablet review 2026-11-01:
// it read NOT BUILT, developer text on the player's screen).
// The VON adapter's own rows first (user, 2026-10-24: a volume, voice activation):
// a slider's optional fourth field is its top (the beep volume's is RADIO_BEEP_MAX).
#define RADIO_SOUNDS [["VOICE VOLUME", "jmfsb_adapter_von_masterVolume", "slider", 1], ["VOICE ACTIVATION", "jmfsb_adapter_von_vad", "bool"], ["VA ON CALLS", "jmfsb_adapter_von_vaCalls", "bool"], ["RADIO BEEPS", "jmfsb_voice_radioBeeps", "bool"], ["CALL BEEPS", "jmfsb_voice_callBeeps", "bool"], ["BEEP VOLUME", "jmfsb_voice_beepVolume", "slider"], ["PITCH PER NET", "jmfsb_voice_pitchPerNet", "bool"], ["STATIC BY QUALITY", "jmfsb_voice_staticByQuality", "bool"]]
// THE NETS RIGHT COLUMN'S SUB-TABS (tablet review 2026-11-01, 3.8): SOUNDS
// and KEYS each take the whole column - KEYS under SOUNDS was cut off at the
// bottom. The pick is kept in uiNamespace (QGVAR(radioSide)).
#define RADIO_SIDE_TABS [["sounds", "SOUNDS"], ["keys", "KEYS"], ["buttons", "BUTTONS"]]
// BUTTONS (user, 2026-11-07: "a player should be able in the radio app to set
// which buttons are what"): the twelve net buttons of the device net rows,
// jmfsb_devices' NET_PAGE_SIZE to a page (keep in step), each set to a net he
// is on or AUTO (FUNC(appRadioButtons), jmfsb_devices_fnc_netAssign). What a
// button reads set to AUTO, and to a net he is not on now. The columns: the
// button, its setting, the net on it now - each a share of the panel's width.
#define RADIO_NET_PAGE_SIZE 4
#define RADIO_NET_PAGE_NAMES ["QUICK", "PAGE 2"]
#define RADIO_BUTTON_AUTO "AUTO"
#define RADIO_BUTTON_ABSENT "%1 (NOT ON IT)"
#define RADIO_BUTTON_LABEL_K 0.28
#define RADIO_BUTTON_SET_K 0.42
#define RADIO_BUTTON_STEP 1.2
// Keys a player cannot do without: unbound, each is a warning line at the top
// of RADIO > NETS. [name said, CBA action].
#define RADIO_KEYS_ESSENTIAL [["TROOPS IN CONTACT", QGVAR(ticKey)], ["PTT 1", QEGVAR(adapter_von,ptt_1)]]
// A CBA bind's DIK at or below this is no key at all.
#define RADIO_KEY_NONE 1
#define RADIO_BEEP_STEP 0.1
// The voice addon's beep volume runs 0 to 2 (its MAX_BEEP_VOLUME).
#define RADIO_BEEP_MAX 2
#define RADIO_BEEP_DECIMALS 2
// KEYS: what each numpad key does, read off the player's own CBA bindings
// (CBA_fnc_getKeybind) so a rebound key shows as rebound. [does, [action, ...]]
// in the JMSB keybind category; the device keys are jmfsb_devices', TIC is ours.
#define RADIO_KEY_ROWS [ \
    ["device keys F1 F2 F3 F4", [QEGVAR(devices,button_F1), QEGVAR(devices,button_F2), QEGVAR(devices,button_F3), QEGVAR(devices,button_F4)]], \
    ["device arrows: net page left / right (tablet: live tiles), cursor", [QEGVAR(devices,button_left), QEGVAR(devices,button_right)]], \
    ["open / close tablet", [QEGVAR(devices,tabletKey)]], \
    ["RADIO app on the phone or side device", [QEGVAR(devices,radioAppKey)]], \
    ["previous / next tab (small devices)", [QEGVAR(devices,tabPrev), QEGVAR(devices,tabNext)]], \
    ["TROOPS IN CONTACT - answers a ringing call first", [QGVAR(ticKey)]], \
    ["answer / hang up call  -  decline", [QEGVAR(devices,answerKey), QEGVAR(devices,declineKey)]], \
    ["voice activation on / off", [QEGVAR(devices,vadKey)]], \
    ["PTT 1 (active net) 2 3 4 (hold) / talk local (hold)", [QEGVAR(adapter_von,ptt_1), QEGVAR(adapter_von,ptt_2), QEGVAR(adapter_von,ptt_3), QEGVAR(adapter_von,ptt_4), QEGVAR(adapter_von,talkLocal)]], \
    ["open channel NET / LOCAL (voice activation)", [QEGVAR(adapter_von,openToggle)]], \
    ["radio voice volume - / +", [QEGVAR(adapter_von,volumeDown), QEGVAR(adapter_von,volumeUp)]] ]
// The walking view's F-keys (jmfsb_devices' button settings, these by default).
// The numpad standard (user, 2026-10-24): answering is numpad 6, so the F-keys
// no longer repeat it.
#define RADIO_WALK_KEYS [["F1", "ear for the active net; quick add during a call"], ["F2", "mute the active net"], ["F3", "map zoom in"], ["F4", "map zoom out"]]
// A text box: the board's search, which a redraw must not pull out from under
// the fingers typing in it.
#ifndef CT_EDIT
    #define CT_EDIT 2
#endif
// A drop-down (NET BUTTONS): a redraw would close it under the pointer.
#ifndef CT_COMBO
    #define CT_COMBO 4
#endif

// DRONES. Below this link quality control is lost (docs/DESIGN_RF.md, "What
// quality does": drones).
#define DRONE_LINK_LOST 0.2
#define DRONES_TABS [["fleet", "FLEET"], ["enemy", "ENEMY"]]
// The jamming addon's drone domain (its DOM_UAV), asked at each drone.
#define DRONES_JAM_DOMAIN "uav"
#define DRONES_REFRESH 2
// The redraw key's steps: quality and battery in tenths, an enemy contact's
// range per 100 m and bearing per 10 deg - finer moves do not rebuild the board.
#define DRONES_KEY_STEPS 10
#define DRONES_KEY_RANGE_M 100
#define DRONES_KEY_BRG_DEG 10
// A bearing reads as three digits, zero-padded, so the column holds still.
#define DRONES_BRG_DIGITS 3
// ENEMY's BEARING SCOPE (review 2026-11-01, decision R7): the player in the
// centre, a ring at each of the receiver's two warning distances (alert 1 km,
// warn 2 km - jmfsb_hacking's sweep), the outer one the scope's edge (m). A
// ring is DRONES_SCOPE_DOTS dots of DRONES_SCOPE_DOT_PX; the player and the
// contact are squares of these pixels. The scope takes at most this share of
// the panel's width; the key/values sit beside it.
#define DRONES_SCOPE_RINGS [1000, 2000]
#define DRONES_SCOPE_RANGE_M 2000
#define DRONES_SCOPE_DOTS 48
#define DRONES_SCOPE_DOT_PX 2
#define DRONES_SCOPE_SELF_PX 6
#define DRONES_SCOPE_CONTACT_PX 10
#define DRONES_SCOPE_SHARE 0.5
#define DRONES_M_PER_KM 1000
// The FEED's render-to-texture: the surface name (one per machine - one feed
// at a time) and its resolution.
#define DRONES_FEED_RTT QGVAR(droneFeed)
#define DRONES_FEED_RES 512
// How often the HUD text over the feed is rewritten (s). The picture itself is
// the engine's, every frame.
#define DRONES_HUD_TICK 0.5
// A drone with no gunner-optic memory points looks ahead and down from its
// centre (a model-space direction), and the target line is cast this far (m).
#define DRONES_FEED_LOOK [0, 0.7071, -0.7071]
#define DRONES_FEED_RANGE 5000
// ORBIT: the loiter circle laid at the drone's position (m).
#define DRONES_ORBIT_RADIUS 300
// MARK: the local marker MARK TARGET drops.
#define DRONES_MARK_NAME QGVAR(droneMark)
#define DRONES_MARK_TYPE "mil_destroy"
// GO TO: the map pick (FUNC(appDronesPick)) - how long an armed pick waits for
// a click before it lets the map go (s), how often it checks (s), and the
// mouse buttons that pick and cancel.
#define DRONES_PICK_S 30
#define DRONES_PICK_TICK 0.5
#define DRONES_MOUSE_PICK 0
#define DRONES_MOUSE_CANCEL 1
// Drone40 MODE switches (jmfsb_drone40_fnc_setMode), in the order drawn.
#define DRONES_MODES [["relay", "RELAY"], ["decoy", "DECOY"], ["jammer", "JAMMER"], ["off", "OFF"]]
// RTB: an airframe of this kind sets down at home, any other loiters there
// (jmfsb_devices' UAV_LAND_KIND - the same test).
#define DRONES_LAND_KIND "Helicopter"

// HACK. How often the open board asks the server what RF it can hear (s), and
// how many LOG lines it keeps.
#define HACKAPP_RF_ASK 5
#define HACKAPP_LOG_MAX 8
// The LOG notes progress at every quarter.
#define HACKAPP_LOG_STEPS 4
#define HACKAPP_REFRESH 1
// The suite's "never hacked" stamp on a tower (jmfsb_hacking_lastHack's default);
// anything above half of it is a real time.
#define HACKAPP_NEVER -1e9
// The DISABLE / SPOOF / TAP segments, in the design's order.
#define HACKAPP_ACTIONS ["DISABLE", "SPOOF", "TAP"]
// The PRODUCT choices sit two to a line.
#define HACKAPP_PRODUCT_COLS 2

// THE JAMMING APP AS THE JAMMER'S CONTROL PANEL (jmfsb_ew_fnc_appEa): its size
// on the vanilla map (a device host gives it the whole map area), and the
// scanner reading's per-domain jamming figures - RADIO, DATA, GPS - that
// decide whether it redraws.
#define JAMMER_PANEL_W 0.9
#define JAMMER_PANEL_H 0.86
#define JAM_READ_FROM 8
#define JAM_READ_COUNT 3

