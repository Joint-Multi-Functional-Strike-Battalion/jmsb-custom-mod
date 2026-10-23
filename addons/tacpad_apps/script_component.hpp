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

// THE SETTINGS APP'S ROWS (FUNC(appSettings)): how much of the pane a stepper's
// value takes - wide enough for a list's choice by name, not only a number -
// and the word a row the server or mission forces carries instead of controls.
#define SETTINGS_STEP_VALUE_W 0.3
#define SETTINGS_LOCKED "LOCKED"

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
#define SUP_CHECK_K 0.9

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
// jmfsb_voice_system: "von" is our game voice; "tfar" / "acre" a radio mod
// whose nets the voice API serves (calls are game voice only).
#define VOICE_SYSTEM_VON "von"
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
#define RADIO_SOUNDS [["RADIO BEEPS", "jmfsb_voice_radioBeeps", "bool"], ["CALL BEEPS", "jmfsb_voice_callBeeps", "bool"], ["BEEP VOLUME", "jmfsb_voice_beepVolume", "slider"], ["PITCH PER NET", "jmfsb_voice_pitchPerNet", "bool"], ["STATIC BY QUALITY", "jmfsb_voice_staticByQuality", "bool"]]
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
    ["TROOPS IN CONTACT", [QGVAR(ticKey)]] ]
// The walking view's F-keys (jmfsb_devices' button settings, these by default).
#define RADIO_WALK_KEYS [["F1", "accept a call"], ["F2", "ear for the active net; quick add during a call"], ["F3", "mute the active net"], ["F4", "decline or hang up"]]
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

