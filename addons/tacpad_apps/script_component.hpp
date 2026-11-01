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
// red alert, amber warn, green ok. Fixed, never themed, like the swatches
// below. The tint's and the badge's alpha.
#define TILE_RED [1, 0.337, 0.235, 1]
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

// THE WEATHER PAGE'S VALUE COLUMN (user, 2026-10-30: "move this data to the
// left, hard to read across screen like this"): where each row's value starts,
// as a share of the row's width, left-aligned there. The labels are tracked
// uppercase - C L O U D  C O V E R, F I R S T  L I G H T - so the column sits
// at the top of the 0.35-0.40 band asked for, to keep the longest of them on
// one line at the larger text sizes.
#define WX_VALUE_AT 0.4

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
// LIVE TILES, per player (user, 2026-10-24: "turn on and off live tiles in
// settings and assign a slot"): every tile the band can carry, in its default
// order, and the setting that holds "id:slot" / "id:off" pairs. A tile with no
// entry is AUTO - shown, in default order after the placed ones.
#define TILE_CHOICES [["vehicle", "VEHICLE"], ["drones", "DRONES"], ["jam", "JAM"], ["weather", "WEATHER"], ["timer", "TIMER"], ["radio", "RADIO"], ["msg", "MSG"], ["arty", "ARTY"], ["medic", "MEDIC"], ["hack", "HACK"], ["intel", "INTEL"], ["support", "SUPPORT"], ["pac", "PAC"]]

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
// The SUPPORT tile's qualifier names the first type in this many letters, so
// "TRANSPORT 1" fits the badge as "TRANS 1".
#define SUP_QUALIFIER_CHARS 5
// THE MENU APP (user, 2026-10-30: "add a menu icon to get to each app and
// settings"; the tablet bar's MENU): every app the tiles know and SETTINGS,
// one row each. Its frame, in safe-zone fractions.
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
// The PAC tile's kicker and detail read larger (user, 2026-10-24).
#define TILE_TEXT_K_PAC 1.35
// Unread traffic of these priorities makes the MSG tile an alert.
#define MSG_URGENT_PRIORITIES ["FLASH", "IMMEDIATE", "HIGH"]

// THE THREE POINTS A SUPPORT REQUEST CAN CARRY, and the variables each lives
// in. Written once, as a macro, because four separate places fill them - the
// form's rows, the map click, the marker list and the confirm - and three
// copies of "which variable is the ingress point" is three chances to write
// the target into the egress slot.
//
// Slot 0 is the target and keeps the ORIGINAL variable names: artillery and
// ALiVE's own CAS have always read supportPoint, and renaming it to suit a new
// asset type would have been a rename across a screen that already works.
#define SUP_SLOT_TARGET  0
#define SUP_SLOT_INGRESS 1
#define SUP_SLOT_EGRESS  2
#define SUP_SLOT_VARS [    [QGVAR(supportPoint), QGVAR(supportPointName)],    [QGVAR(supportIngress), QGVAR(supportIngressName)],    [QGVAR(supportEgress), QGVAR(supportEgressName)]]

// THE PARAMETER-ARRAY SLOTS INGRESS AND EGRESS TRAVEL IN (support core README,
// slots 8 and 9). A provider that declares a point on either (task
// declaration field 7) gets the INGRESS / EGRESS row itself, so a point
// picked for a CAS drone and one picked for a support_air run are the same
// variable. Any other declared point is keyed by its own slot - see
// FUNC(supportPointVars).
#define SUP_PARAM_INGRESS 8
#define SUP_PARAM_EGRESS 9
#define SUP_POINT_KEY(s) (switch (s) do {case SUP_PARAM_INGRESS: {SUP_SLOT_INGRESS}; case SUP_PARAM_EGRESS: {SUP_SLOT_EGRESS}; default {s}})

// A task with more rows than this lists them two to a line, label only - a
// transport offers a dozen, and one per line pushed CONFIRM off the form.
#define SUP_TASK_COLUMNS_AT 5

// The live overlay: how far (m) an approach bearing is drawn out from its
// point when the map is zoomed too far in for a pixel length to mean much.
#define SUP_APPROACH_PX 70

// THE SUPPORT PARAMETER ARRAY'S DEFAULT - radius, altitude, ROE index, speed
// index, arty ordnance index, rounds index, dispersion, guns. One literal, so
// the steppers, the confirm and the map overlay cannot start from different
// numbers.
#define SUP_PARAMS_DEFAULT [500, 150, 0, 1, 0, 1, 100, 0]

// ROE INDEX -> ENGINE COMBAT MODE is the ALiVE provider's (adapter_alive's
// FUNC(supportTask)):
// 0 RED, 1 GREEN, 2 WHITE, 3 YELLOW, 4 BLUE. 0 and 1 are the two values the old
// free/hold stepper wrote, so a stored parameter array keeps its meaning.
// These are the words for each index, and the order a stepper walks them in -
// least to most permissive.
#define SUP_ROE_TEXT ["Fire at will, engage at will", "Hold fire — defend", "Hold fire, engage at will", "Fire at will", "Never fire"]
#define SUP_ROE_ORDER [4, 1, 2, 3, 0]

// ORDER UNIT RTB double-confirms: the first press arms it, a second inside
// this many seconds commits, anything else disarms.
#define SUP_RTB_ARM_WINDOW 3

// A committed tasking stays lit for this long even while the asset still
// reads idle - the FSM takes a beat to flip its status after the order lands.
#define SUP_COMMIT_GRACE 30

// The order the CAS screen lists the ROE indices in - the handoff's: the two
// holds, the two frees, never fire last.
#define SUP_ROE_LIST [1, 2, 3, 0, 4]
#define SUP_ROE_MODES ["RED", "GREEN", "WHITE", "YELLOW", "BLUE"]

// The support core provider kind whose rows fly the run the player draws -
// target, INGRESS and EGRESS, and their stores as ORDNANCE (the CAS drones).
#define SUP_KIND_DRAWN_RUN "cas"

// The provider kinds the legacy per-type PARAMETERS layout and the ROE list
// are drawn for: the ALiVE provider, the only one that reads those slots.
// Before a unit is picked they are drawn only while every row of the type is
// one of these - see FUNC(appSupport).
#define SUP_KINDS_LEGACY ["alive"]

// The declared stepper labels that size a task's effect area on the map -
// support_air's RADIUS, support_fires' SHEAF and SEARCH RADIUS.
#define SUP_RADIUS_LABELS ["RADIUS", "SHEAF", "SEARCH RADIUS"]

// ----------------------------------------------------- where support draws --
// The app id TAC//SUPPORT is registered under.
#define SUP_APP "support"

// ITS OWN DIALOG ON THE VANILLA MAP, THE HOST'S APP AREA ON THE TABLET. On the
// native host the board is the QGVAR(supportDlg) dialog and measures itself in
// the safe zone, as it always has; on the tablet it draws on the device dialog
// and measures itself in the host rectangle like every other app, so its type
// and rows shrink with the screen. One unit pair for the board and its helpers.
#define SUP_UNIT_W ([safeZoneW, HOST_W] select HOST_DEVICE)
#define SUP_UNIT_H ([safeZoneH, HOST_H] select HOST_DEVICE)
#define SUP_ORIGIN_X ([safeZoneX, HOST_X] select HOST_DEVICE)
#define SUP_ORIGIN_Y ([safeZoneY, HOST_Y] select HOST_DEVICE)

// The board's rectangle, [x, y, w, h] in those units: centred two thirds of
// the safe zone on the vanilla map (dialog.hpp's original panel), nearly the
// whole app area on the tablet, where the map it picks on is the screen.
#define SUP_FRAME_NATIVE [0.17, 0.17, 0.66, 0.66]
#define SUP_FRAME_TABLET [0.01, 0.01, 0.98, 0.98]

// The board's layout as fractions of its own rectangle: the title bar, the
// map hole's left edge (the form column's width) and its bottom edge (the
// RTB / CLOSE stack below it). The numbers dialog.hpp's panel was drawn with.
#define SUP_HEAD_K (0.03 / 0.66)
#define SUP_MAP_L_K ((0.545 - 0.17) / 0.66)
#define SUP_MAP_B_K ((0.72 - 0.17) / 0.66)

// The tab row and a checklist line, in rows.
#define SUP_TABS_K 1.3
// TAC//SUPPORT reads larger than the rest of the suite (user, 2026-10-24:
// "support needs bigger fonts"): the cells' and steppers' text scaled, and
// each section opened by a solid band (fnc_supportGroup) rather than a rule.
#define SUP_TEXT_K 1.15
#define SUP_CHECK_K 0.9

// DANGER CLOSE (user, 2026-10-30): the task types that put ordnance on a
// point. CONFIRM on one of them waits for YES / NO when a friendly is inside
// the danger-close setting's distance of the target; this many are named,
// on this many checklist-height rows.
#define SUP_DANGER_TYPES ["arty", "cas"]
#define SUP_DANGER_NAMES_MAX 4
#define SUP_DANGER_ROWS 2

// What the request's one point is called when its task does not say
// (task declaration field 6, addons/support/README.md).
#define SUP_POINT_DEFAULT "TARGET"

// IS THE BOARD ON SCREEN. The dialog on the vanilla map; on the tablet, the
// open app on a live host - the board has no display of its own there.
#define SUP_SHOWN ([!isNull (uiNamespace getVariable [QGVAR(supportDlg), displayNull]), (uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isEqualTo SUP_APP && {!isNull HOST_DISPLAY}] select HOST_DEVICE)


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
// A call is one custom channel of at most this many people; eight calls at once.
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
// The check mark of the WHO CAN table, written as a number so the file stays ASCII.
#define CHECK_MARK (toString [10003])
// The separator a contact's tags follow, likewise.
#define MIDDOT_TEXT (toString [183])
#define SECONDS_PER_MINUTE 60
// SOUNDS (DESIGN_VOICE.md, "Sounds": radio beeps on/off, call beeps on/off, one
// beep volume, pitch per net, static by quality): [label, the voice addon's
// CBA setting, "bool" or "slider"]. A setting the voice addon does not declare
// reads NOT BUILT rather than a switch that switches nothing.
// The VON adapter's own rows first (user, 2026-10-24: a volume, voice activation):
// a slider's optional fourth field is its top (the beep volume's is RADIO_BEEP_MAX).
#define RADIO_SOUNDS [["VOICE VOLUME", "jmfsb_adapter_von_masterVolume", "slider", 1], ["VOICE ACTIVATION", "jmfsb_adapter_von_vad", "bool"], ["VA ON CALLS", "jmfsb_adapter_von_vaCalls", "bool"], ["RADIO BEEPS", "jmfsb_voice_radioBeeps", "bool"], ["CALL BEEPS", "jmfsb_voice_callBeeps", "bool"], ["BEEP VOLUME", "jmfsb_voice_beepVolume", "slider"], ["PITCH PER NET", "jmfsb_voice_pitchPerNet", "bool"], ["STATIC BY QUALITY", "jmfsb_voice_staticByQuality", "bool"]]
// The share of the NETS right column the SOUNDS panel takes, now that it has
// eight rows over the KEYS panel.
#define RADIO_SOUNDS_SPLIT 0.66
#define RADIO_BEEP_STEP 0.1
// The voice addon's beep volume runs 0 to 2 (its MAX_BEEP_VOLUME).
#define RADIO_BEEP_MAX 2
#define RADIO_BEEP_DECIMALS 2
// KEYS: what each numpad key does, read off the player's own CBA bindings
// (CBA_fnc_getKeybind) so a rebound key shows as rebound. [does, [action, ...]]
// in the JMSB keybind category; the device keys are jmfsb_devices', TIC is ours.
#define RADIO_KEY_ROWS [ \
    ["device keys F1 F2 F3 F4", [QEGVAR(devices,button_F1), QEGVAR(devices,button_F2), QEGVAR(devices,button_F3), QEGVAR(devices,button_F4)]], \
    ["device arrows: active net left / right, cursor", [QEGVAR(devices,button_left), QEGVAR(devices,button_right)]], \
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

