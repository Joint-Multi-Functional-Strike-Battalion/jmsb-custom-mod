#define COMPONENT ew
#define COMPONENT_BEAUTIFIED EW
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_EW
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_EW
    #define DEBUG_SETTINGS DEBUG_SETTINGS_EW
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The tacpad's drawing grammar - host rectangle, row height, padding, rules -
// so the EW app is drawn in the same hand as every other app.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// EW IS RULES ON TOP OF RF (docs/DESIGN_EW.md). Same registry, same link
// budget: emitters are RF nodes handed over by RF's listener hook, jammers are
// RF noise through its noise-source hook, decoys are RF nodes marked
// intent "decoy". RF never knows what EW is; EW reads RF only through its
// public calls.

// --- Who owns what -----------------------------------------------------------
#define OWNER_TAG           QUOTE(ADDON)
#define APP_ID              "ew"
#define INTENT_KEY          "intent"
#define INTENT_DECOY        "decoy"
#define INTENT_JAM          "jam"
#define INTENT_SPOOF        "spoof"
#define NET_DATA            "DATA"

// --- Emitter sources (the "source" field of a collected emitter) -------------
#define SRC_RF              "rf"
#define SRC_JAMMER          "jammer"
#define SRC_EXTERNAL        "ext"
#define SRC_ZONE            "zone"

// --- Classes a track is given (DESIGN_EW "Identify") -------------------------
#define CLASS_COMMS         "COMMS"
#define CLASS_DATA          "DATA"
#define CLASS_VIDEO         "VIDEO"
#define CLASS_JAM           "JAM"
#define CLASS_SPOOF         "SPOOF"
#define CLASS_DECOY         "DECOY?"
#define CLASS_UNKNOWN       "UNKNOWN"
// "decoy?" when a set has carried no traffic for this long since first heard.
#define DECOY_QUIET_S       120

// --- Equipment (classes defined in this addon) -------------------------------
// The receiver is the "dedicated" DF set and an anti-spoof GPS, carried or in
// the cargo of the vehicle the man is in. The jammer module only works from a
// vehicle's cargo - no man packs (user, 2026-10-21). The class keeps its old
// name so missions that stock it still load.
#define ITEM_RECEIVER       QGVAR(receiver)
#define ITEM_JAMMER_PACK    QGVAR(jammerPack)

// --- DF (DESIGN_EW "ES") -----------------------------------------------------
// Bearing error by set class, worst first; ISR players get one class better.
#define DF_CLASSES          [15, 10, 5, 2]
#define DF_ERR_DEDICATED    2
// [profile, error deg]. A profile not listed cannot DF (drone links, legacy
// commercial sets).
#define DF_PROFILES         [["handheld", 15], ["manpack", 10], ["relay", 10], ["vehicle", 5], ["satcom", 10]]
// What a dedicated receiver hears: every band.
#define BANDS_ALL           ["VHF", "UHF", "SAT", "VIDEO"]
// A cut needs this much SNR at the sensor; the error grows as the SNR drops
// below the good figure, up to the cap multiple.
#define DETECT_SNR_DB       0
#define SNR_GOOD_DB         20
#define ERR_MAX_MULT        3
// Sensors of one side that take a cut on one emitter per DF tick, nearest first.
#define CUTS_PER_EMITTER    3
// Two cuts make a fix only from sensors this far apart and crossing at least
// this angle; the fix error is capped.
#define FIX_MIN_BASELINE_M  50
#define FIX_MIN_CROSS_DEG   10
#define FIX_ERR_MAX_M       2000
// Confidence from the fix falls to nothing at this error.
#define FIX_ERR_POOR_M      500
// Cuts kept on a track (newest), and how far a DF line is drawn.
#define CUTS_KEPT           8
#define DF_LINE_M           4000
// A detection range ceiling, so a 50 W set does not price pairs across the map.
#define DETECT_MAX_M        12000
// DF ON YOU is told to one man once per this many seconds.
#define DF_ON_YOU_COOLDOWN  30
// Terrain samples along a DF path (as RF's own budget does).
#define TERRAIN_SAMPLES     3

// --- Emission (DESIGN_EW "EP": EMCON) ----------------------------------------
// The chance per DF tick that an idle set is caught beaconing, by EMCON level
// 0..3 (a set carrying traffic is always caught). 3 SILENT never emits.
#define BEACON_DUTY         [0.5, 0.25, 0.1, 0]
// EMCON 1 and above caps power at 2 W.
#define EMCON_POWER_CAP_DBM 33
#define EMCON_SILENT        3
#define EMCON_LEVELS        ["NORMAL", "REDUCED", "MINIMISE", "SILENT"]
// Exposure is priced against a generic enemy receiver.
#define EXPOSURE_SENS_DBM   -115
#define EXPOSURE_GAIN_DBI   3

// --- EA (DESIGN_EW "EA") -----------------------------------------------------
#define MODE_BARRAGE        "barrage"
#define MODE_SPOT           "spot"
#define MODE_SWEEP          "sweep"
#define MODE_GPS            "gps"
#define MODE_SPOOF          "spoof"
#define MODES               [MODE_BARRAGE, MODE_SPOT, MODE_SWEEP, MODE_GPS, MODE_SPOOF]
// Modes only an ISR player may run (DESIGN_EW "Player skill").
#define MODES_ISR           [MODE_SPOT, MODE_SPOOF]
// What a vehicle's jammer module can put out.
#define VEHICLE_BANDS       ["VHF", "UHF", "SAT", "VIDEO"]
// Power steps dBm: 1 W, 5 W, 20 W, 50 W.
#define POWER_VEHICLE       [30, 37, 43, 47]
#define DUTY_STEPS          [0.25, 0.5, 0.75, 1]
#define JAM_GAIN_DBI        3
// Spot: +10 dB, and the target's spread gain halved. RF subtracts the
// receiver's whole spread, so half of the 20 dB of an MPU5 is
// handed back.
#define SPOT_GAIN_DB        10
#define SPOT_SPREAD_BACK_DB 10
// Sweep: each band gets the full power for this long, in turn.
#define SWEEP_DWELL_S       5
// GPS jamming radius by power step (a jamming-addon zone on the host).
#define GPS_RADIUS_STEPS    [200, 400, 700, 1000]
#define JAM_ZONE_DOMAINS    ["gps"]
// The transmitted power ES hears from a jamming-addon site (it has no dBm of
// its own) and from an external emitter that gave none.
#define SITE_TX_DBM         47
// Jamming-addon domains -> the bands its site radiates on.
#define ZONE_DOMAIN_BANDS   [["radio", ["VHF", "UHF"]], ["data", ["UHF"]], ["gps", ["SAT"]]]

// --- The jammer module as a set (user, 2026-10-21: the panel's device ID,
// power system, pattern, frequency and auto-engage - "i want them all") ------
// DEVICE ID: per side, the lowest number free when the jammer first exists,
// kept while it exists.
#define DEV_ID_FORMAT       "GJ-%1"
#define DEV_ID_DIGITS       2
// PATTERN, by the names rf's patternGain takes (RF_PATTERN_OMNI / _SECTOR).
// A sector is this wide about its azimuth, this much stronger inside it, and
// reaches nothing outside; the azimuth steps this far a press.
#define PATTERN_OMNI        "omni"
#define PATTERN_SECTOR      "sector"
#define PATTERNS            [PATTERN_OMNI, PATTERN_SECTOR]
#define SECTOR_WIDTH_DEG    120
#define SECTOR_GAIN_DB      3
#define AZIMUTH_STEP_DEG    15
#define DEGREES_FULL        360
// FREQ FILTER (barrage): broadband sits on the whole band; targeted only on
// the nets within half this bandwidth of the tuned MHz (rf's netFreq), its
// power put into that slice. Targeted is tuned off ES tracks: ISR only, as
// spot is.
#define FILTER_BROADBAND    "broadband"
#define FILTER_TARGETED     "targeted"
#define FILTERS             [FILTER_BROADBAND, FILTER_TARGETED]
#define TARGET_BW_MHZ       1
#define TARGET_GAIN_DB      6
// MHz on screen: three places below this, whole MHz above it.
#define MHZ_COARSE_ABOVE    1000
#define MHZ_DECIMALS        3
// OPERATION: continuous transmits whenever switched on; auto only while a
// hostile drone or a hostile emitter on its band is in reach, looked at every
// AUTO_CHECK_S.
#define OP_CONTINUOUS       "continuous"
#define OP_AUTO             "auto"
#define OPERATIONS          [OP_CONTINUOUS, OP_AUTO]
#define AUTO_CHECK_S        15
#define AUTO_WHY_DRONE      "HOSTILE DRONE"
// POWER SYSTEM, kept on the host vehicle (it outlives an operator):
// [battery Wh, heat %, flat, thermal cutout, W in, W drawn, generator on].
// The draw is the mean RF out over the amplifier's efficiency; heat rises
// with the mean RF out as a share of the top power step.
#define JAM_POWER_FRESH     [GVAR(jamBatteryWh), 0, false, false, 0, 0, false]
#define JAM_PA_EFFICIENCY   0.4
#define JAM_TOP_W           50
#define SECONDS_PER_HOUR    3600
// HEAT %: thermal cutout at the top, back on air at the foot of the
// hysteresis, HOT from here up. Battery LOW below this share.
#define HEAT_CUTOUT         100
#define HEAT_RESUME         60
#define HEAT_HOT            80
#define BATTERY_LOW_FRAC    0.25

// --- Decoys ------------------------------------------------------------------
// A ground antenna that copies a profile's band and power and claims one net
// under a key nobody holds - the drone40 decoy's recipe.
#define DECOY_CLASS         "OmniDirectionalAntenna_01_olive_F"
#define DECOY_PROFILES      ["handheld", "manpack", "legacy"]
#define DECOY_KEY_FORMAT    "ewdecoy_%1"
#define DECOYS_PER_MAN      2

// --- GPS spoof ---------------------------------------------------------------
// Drift grows at this rate inside a spoofer's field and decays this many times
// as fast outside it.
#define SPOOF_RATE_MPS      3
#define SPOOF_DECAY_MULT    2
#define GPS_GOOD            "GOOD"
#define GPS_SUSPECT         "SUSPECT"
#define GPS_SPOOFED         "SPOOFED"
// Denied: the jamming addon's GPS field has taken the receiver's lock
// (jmfsb_jamming_gpsDenied). Readers show no position at all.
#define GPS_NOFIX           "NO FIX"
#define GPS_NOFIX_NOTE      "NO GPS FIX - THE RECEIVER HAS NO LOCK. READ YOUR GRID OFF THE MAP."
#define GPS_SUSPECT_NOTE    "GPS SUSPECT - A SPOOFER IS IN THE AIR. CHECK THE GRID AGAINST THE MAP."
#define GPS_NOTE_TITLE      "GPS"

// --- Hacked spoof (the hacking addon's SPOOF action) -------------------------
// A broken net's GPS is walked off by the same engine as a spoofer's field,
// for the hack-spoof setting's length, then walks back.
#define DEFAULT_SPOOF_HACK_TIME 300

// --- AI EW (DESIGN_EW "Both ways: AI EW", D17) -------------------------------
// Skill of the enemy side's AI: 0 OFF, 1 BASIC, 2 ACTIVE, 3 SMART.
#define AI_OFF              0
#define AI_BASIC            1
#define AI_ACTIVE           2
#define AI_SMART            3
#define DEFAULT_AI_SKILL    AI_BASIC
#define DEFAULT_AI_RANGE    1500
// A group's radio set is looked up again after this long.
#define AI_SET_REFRESH_S    30
// The rank of a set that can talk but not DF, so any DF set beats it.
#define AI_SET_NO_DF        1000
// AI sensors tried per emitter per DF tick, nearest first - the DF tick's cost
// cap on a big enemy force (each try casts terrain).
#define AI_DF_TRIES         6
// One reaction per track per this long; drones and QRFs per side per this long.
#define AI_REACT_COOLDOWN_S 120
#define AI_DISPATCH_COOLDOWN_S 300
// How long alerted men keep watching the fix.
#define AI_WATCH_S          60
// THE COMMS GATE (DESIGN_EW "Comms gate the AI"): each hop takes 2 s, the
// chance a report gets through is the link quality, and inside 50 m groups
// share by voice.
#define AI_HOP_S            2
#define AI_VOICE_M          50
// The QRF a SMART side sends to a fix searches this far round it.
#define AI_QRF_RADIUS       300
#define AI_QRF_TAG          "DF FIX"
// What the reaction ladder (jmfsb_reaction) is told caught the man.
#define AI_REACT_SOURCE     "df"
#define HOSTILE_BELOW       0.6

// --- Threats (DESIGN_EW "Threat warning") ------------------------------------
#define THREAT_DF           "DF ON YOU"
#define THREAT_JAMMER       "JAMMER"
#define THREAT_SPOT         "SPOT JAM"
#define THREAT_SPOOFER      "SPOOFER"
#define THREAT_DRONE        "ENEMY DRONE"
#define THREAT_FIX          "NEW FIX"
#define THREATS_KEPT        8
#define THREAT_SHOW_S       180
#define THREAT_COLOUR       [0.914, 0.651, 0.235, 1]

// --- Slice and loops ---------------------------------------------------------
// Positions in the slice are rounded to this, so a man standing still does not
// re-send his side's picture every tick.
#define SLICE_GRID_M        10
#define CLIENT_TICK_S       1
#define APP_REFRESH_S       2

// --- App ---------------------------------------------------------------------
#define APP_W               0.62
#define APP_H               0.70
#define TABS                ["OVERVIEW", "ES", "EA", "EP"]
#define TAB_OVERVIEW        0
#define TAB_ES              1
#define TAB_EA              2
#define TAB_EP              3
// Spectrum bars run from the floor to this much noise above it.
#define SPECTRUM_SPAN_DB    60
#define MAP_ANIM_TIME       0.3
#define MAP_CTRL_TYPE       101

// --- Map layer ---------------------------------------------------------------
#define MAP_DISPLAY         12
#define MAP_CONTROL         51
#define COLOUR_CUT          [0.95, 0.75, 0.2, 0.9]
#define COLOUR_CUT_EDGE     [0.95, 0.75, 0.2, 0.3]
#define COLOUR_FIX          [0.9, 0.25, 0.2, 1]
#define COLOUR_OWN_JAM      [0.3, 0.6, 0.95, 0.8]
#define MAP_ICON_PX         20
#define MAP_TEXT_SIZE       0.04
// CfgMarkers classes whose icons the layer draws with.
#define MAP_MARKER_FIX      "mil_destroy"
#define MAP_MARKER_JAM      "mil_circle"

// --- Setting defaults --------------------------------------------------------
#define DEFAULT_DF_TICK     3
#define DEFAULT_FIX_WINDOW  30
#define DEFAULT_TRACK_TTL   300
#define DEFAULT_DECOY_LIFE  900
#define DEFAULT_SPOOF_RADIUS 800
#define DEFAULT_SPOOF_DRIFT 300
#define DEFAULT_JAM_RANGE   3000
#define DEFAULT_JAM_BATTERY_WH 150
#define DEFAULT_JAM_CHARGE_W 300
#define DEFAULT_JAM_HEAT_RISE 0.5
#define DEFAULT_JAM_HEAT_COOL 0.1
#define AI_SKILL_NAMES      ["OFF", "BASIC", "ACTIVE", "SMART"]

// --- THE EA PANEL (FUNC(appEa), user 2026-10-21: a ground-jammer control
// panel) --------------------------------------------------------------------
// Columns as fractions of the body: the controls on the left, the air on the
// right, this much between them; the legend's share of the right column.
#define PANEL_LEFT_W        0.46
#define PANEL_GAP_W         0.02
#define PANEL_LEGEND_W      0.32
// A setting row's label sits in this share of the left column, its cells in
// the rest; a readout between stepper arrows is this many cells wide.
#define PANEL_INLINE_LABEL_W 0.22
#define PANEL_READOUT_WEIGHT 2
// Heights in rows: the state line, a segmented cell, the air after a row,
// the transmitter switch, the network footer, the spectrum graph. A row that
// is not a segmented one steps this far.
#define PANEL_STATE_ROWS    2
#define PANEL_CELL_ROWS     1.15
#define PANEL_ROW_AIR       0.3
#define PANEL_TX_ROWS       1.8
#define PANEL_FOOT_ROWS     2
#define PANEL_GRAPH_ROWS    7
#define PANEL_ROW_STEP      1.3
// Type, as multiples of the shell's body size.
#define PANEL_STATE_SIZE    TEXT_DISPLAY
#define PANEL_SUB_SIZE      TEXT_BODY
#define PANEL_LABEL_SIZE    TEXT_LABEL
#define PANEL_NOTE_SIZE     TEXT_LABEL
#define PANEL_ROW_SIZE      TEXT_BODY
#define PANEL_TX_SIZE       TEXT_TITLE
// A spectrum bar's air each side of its slot, its least height in pixels so a
// clear band still shows; a strength bar's air above and below in its row;
// the legend swatch and its inset in a row.
#define PANEL_BAR_INSET     0.18
#define PANEL_BAR_MIN_PX    2
#define PANEL_BAR_TRACK     0.3
#define PANEL_SWATCH        0.6
#define PANEL_SWATCH_INSET  0.2
// The TRANSMITTER and POWER SYSTEM blocks' key column, as a share of each
// one's half of the right column.
#define PANEL_KEY_W         0.42
// The BATTERY and HEAT bars: where the bar starts in the right column and its
// share of it (the value is right of it).
#define PANEL_POWER_BAR_AT  0.2
#define PANEL_POWER_BAR_W   0.58
// A frequency tick on the spectrum: its height in rows and width in pixels.
#define PANEL_TICK_ROWS     0.5
#define PANEL_TICK_PX       2
// DETECTED: rows shown, and where the strength bar sits in the row; its scale.
#define DETECTED_MAX        5
#define DETECTED_BAR_AT     0.42
#define DETECTED_BAR_W      0.36
#define DBM_BAR_MIN         -120
#define DBM_BAR_MAX         -40
// The side's jammers named in the NETWORK footer.
#define NETWORK_SHOWN       3
// RECENT ALERTS lines at most, when the right column has the room.
#define ALERTS_SHOWN        3
// mW in a W, and a fraction as a percent.
#define MW_PER_W            1000
#define PERCENT             100
// The target stepper's arrows, written as numbers so the file stays ASCII.
#define ARROW_PREV          (toString [9664])
#define ARROW_NEXT          (toString [9654])
#define DEGREE_SIGN         (toString [176])
#define AZIMUTH_DIGITS      3
// SEMANTIC COLOURS, the one place a scheme does not repaint: on air is red
// (the walking view's own net-down red), and the white text on the switch.
// Green is the shell's swatchGreen token.
#define COLOUR_TX_ON        [0.898, 0.224, 0.208, 1]
#define COLOUR_ON_SIGNAL    [1, 1, 1, 1]
