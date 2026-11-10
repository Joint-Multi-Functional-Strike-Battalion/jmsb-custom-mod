#define COMPONENT watch
#define COMPONENT_BEAUTIFIED Watch
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_WATCH
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_WATCH
    #define DEBUG_SETTINGS DEBUG_SETTINGS_WATCH
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"
#include "\a3\ui_f\hpp\definedikcodes.inc"

// THE WATCH HUD (docs/DESIGN_WATCH_HUD.json, decided 2026-11-07). A profile is
// a class or skill set - what it watches, its fields, its report; a slot is one
// watched target. Off by default; the action key (numpad 9) adds what the
// player looks at, again removes it. Six slots - the device's 3 x 2 tiles
// (user, 2026-11-08: "6 tiles 3 wide by 2 tall").
#define SLOTS_PER_PROFILE   6
#define ACTION_KEY          DIK_NUMPAD9
#define ACTION_REACH        15
// World panels: the full panel within FULL_RANGE, a tag beyond TAG_RANGE
// (the shrink setting), nothing past DRAW_RANGE.
#define FULL_RANGE          5
#define TAG_RANGE           15
#define DRAW_RANGE          60
// Auto-clear: a target lost (gone, or past LOST_RANGE) for LOST_SECONDS.
#define LOST_RANGE          300
#define LOST_SECONDS        60
#define TICK_SECONDS        1
// The device F-keys while a profile is on, F1-F4 (devices' button index 0-3),
// and the arrows (4-5) that pick the slot they act on (user, 2026-11-08: "use
// the arrow keys to select them then f keys"; "f2 should be a share key").
#define KEY_REPORT          0
#define KEY_SHARE           1
#define KEY_ALL_OFF         2
#define KEY_SQUAD           3
#define KEY_LEFT            4
#define KEY_RIGHT           5
#define KEY_HINT_WORDS      ["REPORT", "SHARE", "ALL OFF", "SQUAD"]
#define KEY_SELECT_WORD     "SELECT"
// The key hints' icons, F1-F4 (the report key's is the profile's own icon).
#define HINT_ICONS          ["\a3\ui_f\data\igui\cfg\simpletasks\types\radio_ca.paa", "\a3\ui_f\data\igui\cfg\simpletasks\types\upload_ca.paa", "\a3\ui_f\data\igui\cfg\simpletasks\types\exit_ca.paa", "\a3\ui_f\data\igui\cfg\simpletasks\types\meet_ca.paa"]
// SHARE puts the picked slot's target on the same profile of every player
// within SLOT_SHARE_RANGE metres the profile's test accepts (medical: every
// medic - user, 2026-11-08: "f2 puts on ever medic skilled player in 5 m").
#define SLOT_SHARE_RANGE    5
// The profiles' icons (design: first-aid-kit, binoculars, bomb).
#define ICON_RECON          "\a3\ui_f\data\igui\cfg\simpletasks\types\scout_ca.paa"
#define ICON_ENGINEER       "\a3\ui_f\data\igui\cfg\simpletasks\types\destroy_ca.paa"
#define ICON_LEAD           "\a3\ui_f\data\igui\cfg\simpletasks\types\meet_ca.paa"
#define ICON_SELF           "\a3\ui_f\data\igui\cfg\simpletasks\types\help_ca.paa"
#define SCREEN_ID           "watch"
// The walking-view device that shows a second profile (jmfsb_devices).
#define SIDE2_DEVICE        "side2"
#define HOOK_ID             "watch"
// Colours (visual_rules): fill by state, solid border live, dashed stale.
#define COLOUR_RED          [0.9, 0.2, 0.15, 1]
#define COLOUR_AMBER        [0.95, 0.7, 0.15, 1]
#define COLOUR_GREEN        [0.3, 0.75, 0.3, 1]
#define COLOUR_GREY         [0.55, 0.55, 0.55, 1]
#define COLOUR_INK          [0.95, 0.95, 0.93, 1]
#define COLOUR_PANEL        [0.07, 0.07, 0.07, 0.86]
// World text (the contacts' and the JFO's labels, drawIcon3D).
#define HUD_TEXT_SIZE       0.03
#define HUD_TAG_SIZE        0.026
#define HUD_FONT            "RobotoCondensedBold"
#define HUD_SELECTION       "spine3"
#define HUD_SIDE            [0.55, 0, 0.35]
// THE WORLD PANELS ARE UI CONTROLS (user, 2026-11-08: "center and put some
// shading behind it"): on the mission display, centred on the point beside
// the man, the lines centred over a shaded backdrop - the ecoti boxes' way,
// since a drawIcon3D size cannot be pinned down and a backdrop has to fit its
// text. Sizes in pixels AT 1080 LINES (HUD_REF_LINES), scaled to the screen
// by REF_X / REF_Y so the panel is the same share of a 4K screen as of a
// 1080p one (user, 2026-11-08: "useless to small"); a tag (past TAG_RANGE) is
// the narrow panel.
#define HUD_DISPLAY         46
// Hidden while a dialog (the tablet) or the map is up (user, 2026-11-08: "hud
// showing through tablet ... a big no"); larger by request the same day.
#define HUD_TEXT_PIXELS     28
#define HUD_TAG_PIXELS      22
#define HUD_LINE_SPACING    1.2
#define HUD_WIDTH_PIXELS    560
#define HUD_TAG_WIDTH_PIXELS 240
#define HUD_PAD_PIXELS      10
#define HUD_REF_LINES       1080
#define REF_Y(V)            ((V) * safeZoneH / HUD_REF_LINES)
#define REF_X(V)            ((V) * safeZoneH / HUD_REF_LINES * pixelW / pixelH)
#define COLOUR_HUD_BACK     [0, 0, 0, 0.55]
#define PIXEL_X(V)          ((round ((V) / pixelW)) * pixelW)
#define PIXEL_Y(V)          ((round ((V) / pixelH)) * pixelH)
// The device panel: rows per slot and the share of the map it may cover.
#define PANEL_LINES         3
#define PANEL_MAP_SHARE     0.6
#define PANEL_LINE_PAD      1.1
#define PANEL_LINES_FALLBACK 12
// The device panel (user, 2026-11-08: "font to big, and needs to be 3
// across", then "6 tiles 3 wide by 2 tall"): a tile per slot in
// PANEL_COLUMNS columns, TILE_GAP_PIXELS apart, the picked one lit; the type
// this share of the device's row height; the key hints always on the bottom.
// Backdrop, header and hints come before the tiles' controls (two a tile).
#define PANEL_COLUMNS       3
#define PANEL_FONT_SCALE    0.72
#define PANEL_FIXED_CTRLS   3
#define TILE_GAP_PIXELS     3
#define COLOUR_TILE         [0.15, 0.15, 0.14, 0.9]
#define COLOUR_TILE_PICKED  [0.42, 0.33, 0.1, 0.95]
// THE MONITOR TRACES (FUNC(trace), user, 2026-11-08: "is this even a real
// ekg"): a profile's "trace" gives [beats per minute, rhythm, seed, pulse];
// the full world panel draws TRACE_SECONDS of it scrolling under its lines,
// the panel's width, in TRACE_POINTS columns - each a strip over its
// TRACE_SUBSAMPLES samples' low to high, TRACE_LINE_PIXELS at least, so the
// line joins up and a narrow spike is never missed. The EKG is TRACE_PIXELS
// high, its baseline TRACE_BASELINE down and a full R wave TRACE_SCALE of it;
// sinus green, every other rhythm red. The pleth under it is PLETH_PIXELS
// high, cyan.
#define TRACE_SECONDS       4
#define TRACE_POINTS        100
#define TRACE_SUBSAMPLES    4
#define TRACE_PIXELS        110
#define PLETH_PIXELS        50
// Thinner (user, 2026-11-09: "make the ekg lines thinner"): was 3.
#define TRACE_LINE_PIXELS   1
#define TRACE_BASELINE      0.6
#define TRACE_SCALE         0.55
#define TRACE_RHYTHMS       ["sinus", "pea", "vt", "vf", "flat"]
#define TRACE_GREEN         [0.3, 0.95, 0.4, 1]
#define PLETH_CYAN          [0.3, 0.85, 1, 1]
// The complex in seconds from the beat's start: P, the four QRS steps from
// TRACE_Q_AT, T. It is TRACE_COMPLEX_S long and squeezed only when the beats
// come faster than that.
#define TRACE_P_AT          0.02
#define TRACE_P_S           0.08
#define TRACE_Q_AT          0.14
#define TRACE_QRS_STEP      0.02
#define TRACE_T_AT          0.32
#define TRACE_T_S           0.16
#define TRACE_COMPLEX_S     0.5
// A patient's own phase (up to TRACE_SEED_S seconds) and R height (from
// TRACE_R_MIN of full).
#define TRACE_SEED_S        10
#define TRACE_R_MIN         0.8
// The pleth's pulse: TRACE_PLETH_DELAY s after the beat starts, its upstroke
// TRACE_PLETH_RISE of the beat.
#define TRACE_PLETH_DELAY   0.3
#define TRACE_PLETH_RISE    0.15
// VT's floor rate and VF's two wavelets (degrees of phase per second); a
// flat line's drift.
#define TRACE_VT_RATE       160
#define TRACE_VF_A          1700
#define TRACE_VF_B          2900
#define TRACE_FLAT_DRIFT    150
#define TRACE_FLAT_AMP      0.02
// The tablets' watch panel: its default place, safe-zone fractions.
#define PANEL_PLACE         [0.74, 0.30, 0.25, 0.40]
// Contacts (recon, engineer threats): seen solid by friendlies within
// SHARE_RANGE when anyone has line of sight; LOS_VISIBLE of checkVisibility
// counts as seen, aimed LOS_AIM_UP above the object's base.
#define SHARE_RANGE         2000
#define LOS_VISIBLE         0.2
#define LOS_AIM_UP          1
// A slot is kept this long after it is added, while the server publishes it.
#define KEEP_GRACE          5
#define BOX_SOLID           "\a3\ui_f\data\igui\cfg\cursors\select_target_ca.paa"
#define BOX_DASHED          "\a3\ui_f\data\igui\cfg\cursors\lock_target_ca.paa"
#define BOX_SIZE            1.2
#define MARKER_SEEN         "mil_warning"
#define MARKER_LOST         "mil_unknown"
#define MARKER_RECON        "ColorOPFOR"
#define MARKER_THREAT       "ColorOrange"
// A hit part above this damage counts as damaged (engineer vehicle look).
#define DAMAGED_PART        0.1
#define SPOTREP_TEMPLATE    "contactrep"
#define UXO_TEMPLATE        "uxo9"
#define UXO_NET             "ENGINEER"
#define DEFREP_TEMPLATE     "defrep"
// The JFO impact rings: drawn within IMPACT_DRAW_RANGE, IMPACT_RING_SEGMENTS legs,
// IMPACT_LIFT above the ground, the label IMPACT_LABEL_UP above the target.
#define IMPACT_DRAW_RANGE   3000
#define IMPACT_RING_SEGMENTS 36
#define IMPACT_LIFT         0.5
#define IMPACT_LABEL_UP     5
// Self aid: pain above this reads IN PAIN; engine damage above this reads HURT.
#define PAIN_HURT           0.1
#define HURT_DAMAGE         0.1
// The squad view's NO SIGNAL: a man with no item of this prefix has no device.
#define DEVICE_PREFIX       "jmfsb_devices_"
#define NOTE_TITLE          "WATCH"
#define NOTE_COLOUR         [0.761, 0.659, 0.471, 1]
#define ALERT_COLOUR        [0.9, 0.2, 0.15, 1]
#define ACE_ICON            "\a3\ui_f\data\igui\cfg\simpletasks\types\scout_ca.paa"
