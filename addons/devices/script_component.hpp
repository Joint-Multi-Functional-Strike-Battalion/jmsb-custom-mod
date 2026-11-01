#define COMPONENT devices
#define COMPONENT_BEAUTIFIED Devices
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_DEVICES
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_DEVICES
    #define DEBUG_SETTINGS DEBUG_SETTINGS_DEVICES
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The shell's geometry and host macros - HOST_NATIVE and friends. The shell's
// own script_component.hpp is NOT included: it defines COMPONENT, which would
// redirect every PREP in this addon into the shell's folder.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// DIK_F1 and friends for the frame's keys. JMSB's macro header does not pull
// these in; without it DIK_F1 compiles as an undefined variable, not a key.
#include "\a3\ui_f\hpp\definedikcodes.inc"

// A text box, and the style bit that makes it multi-line - FUNC(keyDown) leaves
// the arrows and Enter to a box that has focus.
#ifndef CT_EDIT
    #define CT_EDIT 2
#endif
#ifndef ST_MULTI
    #define ST_MULTI 16
#endif

// THE TABLET DIALOG and the two controls it declares.
//
// 51 FOR THE MAP, ON PURPOSE. It is the map control's idc on the vanilla map
// display, and the shell reaches its map with `displayCtrl 51` - so on this
// display the same call finds ours, and the shell never has to know which host
// it is on.
#define IDD_TABLET 8970
#define IDC_TABLET_MAP 51
#define IDC_TABLET_FRAME 8971
#define IDC_TABLET_BACKDROP 8972

// THE SIX KEYS PRINTED ON THE FRAME, as mouse buttons (FUNC(keyButtons)):
// F1-F4 then LEFT, RIGHT, in CfgJmfsbDevices keys[] order.
#define KEY_COUNT 6
#define SOFT_KEY_COUNT 4
#define KEY_INDEX_LEFT 4
#define KEY_INDEX_RIGHT 5
// The arrows scroll an open screen (FUNC(scrollScreen)): a controls group,
// and the share of its visible height one press moves.
#ifndef CT_CONTROLS_GROUP
    #define CT_CONTROLS_GROUP 15
#endif
#define SCROLL_PAGE 0.75
#define IDC_TABLET_KEY(n) (8973 + (n))

// How far in the map opens: a device in the hand shows the street, not the
// province. ctrlMapScale units; the vanilla map opens at about 0.5.
#define MAP_SCALE_OPEN 0.08

// THE TABLET'S SCREEN (docs/DESIGN_TABLET.md, "Layout"), in design px of its
// 1364 x 1000 screen: the device bar, the notification line, the live tiles and
// the rule under them, the map area (the rest) and the net row. Every row is its
// design height over the design screen's, so both glasses - the large tablet's
// and the vehicle's are the same size in their textures - keep the proportions.
#define TABLET_DESIGN_W 1364
#define TABLET_DESIGN_H 1000
#define TABLET_ROW_BAR 34
#define TABLET_ROW_NOTIFY 30
#define TABLET_ROW_TILES 96
#define TABLET_RULE_TILES 3
// 56 (notes, 2026-10-30; was 48): room for the 40 px cells and their air.
#define TABLET_ROW_NETS 56
// Air inside a row, and the widest a net cell is allowed to grow.
#define TABLET_GAP 8
#define TABLET_NET_CELL_MAX_W 180
// THE SCREEN'S BORDER (user, 2026-10-21: "there needs to be some kind of
// border to the screen"): the map area stands this many design px in from
// the hole's left and right edges and off the net row, the ink showing round
// it as a frame - so the map and its markers never run into the bezel.
#define TABLET_BORDER 8
// Text in the rows, as multiples of the shell's body size (FUNC(drawText)).
// The bar's at 0.95 (user, 2026-10-30: "make font larger"; was 0.75).
#define TABLET_TEXT_BAR 0.95
#define TABLET_TEXT_NOTIFY 0.75
#define TABLET_TEXT_NET 0.7
// The device bar's columns and the notification line's two edge columns, as
// fractions of the row's width: brand | facts | clock | facts | device | MENU
// | ESC CLOSES, and count | newest | time.
#define TABLET_BAR_BRAND_W 0.09
#define TABLET_BAR_ESC_W 0.09
// The bar's right block - the device's name, with room for the battery - sits
// just left of MENU and ESC CLOSES; the left block takes the rest.
// (0.22 left the right-hand facts a tenth of the bar and they wrapped under
// the clock - user, 2026-10-31: "wrapping?")
#define TABLET_BAR_DEVICE_W 0.12
// MENU (user, 2026-10-30: "add a menu icon to get to each app and settings"):
// the word, a hotspot, opens the menu app (jmfsb_tacpad_apps_fnc_appMenu).
#define TABLET_BAR_MENU_W 0.05
#define TABLET_BAR_MENU "MENU"
#define TABLET_MENU_APP "menu"
// The clock stands in the middle of the bar (user, 2026-10-30: "move time to
// center"); the facts split either side of it.
#define TABLET_BAR_CLOCK_W 0.08
// The unseen count's cell: 42 design px, the accent block in the design.
#define TABLET_NOTIFY_COUNT_W 0.031
#define TABLET_NOTIFY_TIME_W 0.07
// Seconds between redraws of the rows, and of the tiles in their row - the
// tiles' own period on the vanilla map (tacpad_apps registers them at 2).
#define TABLET_TICK 0.5
#define TABLET_TILE_PERIOD 2

// THE FRAMES THE TABLET DIALOG WEARS. Each gets the tablet screen's rows; the
// phone and the side devices are the walking view only (FUNC(open) refuses
// them), and their settings live in the tablet's SETTINGS > DEVICES.
#define TABLET_DEVICES ["large", "uav", "vehicle", "rdc"]
#define VEHICLE_DEVICE "vehicle"
// DEVICE VIEWS (fnc_layout): [device, top of what is shown as a fraction of the
// canvas, horizontal stretch]. The vehicle tablet shows from just under its
// handle down - the red box on art/devices/vehicle_src_edit.png, 310 px of 2048 -
// with the handle off the top of the monitor, and is drawn 30% wider (user,
// 2026-10-24).
#define DEVICE_VIEWS [[VEHICLE_DEVICE, 0.152, 1.3]]
// What is not a vehicle to the vehicle tablet, though the engine files it under
// LandVehicle or Air: a mortar, an HMG or AT tripod, and a parachute canopy.
#define VEHICLE_TABLET_EXCLUDED ["StaticWeapon", "ParachuteBase"]
// What the device bar calls each one. The vehicle's reads "VEHICLE . <name>".
#define DEVICE_NAMES [["large", "TABLET"], ["uav", "UAV TABLET"], ["vehicle", "VEHICLE"]]
// The separator the bar and the rail use; one code point, written as a number
// so the file stays ASCII.
#define MIDDOT (toString [183])

// THE TABLET'S FIXED PANEL PLACES (DESIGN_TABLET "Map area"), handed to the
// shell with the host (jmfsb_tacpad_fnc_setHost) and read by its FUNC(place).
// Fractions of the MAP AREA, which is the host on a tablet: 1364 x 789 design
// px, 8 px of air at the edges. Squad rail top left 340 wide (290 until 2026-10-21, user: "make a little wider"); the button strip
// top right 410 wide - TOOLS, SETTINGS, ADMIN, HIDE - with TROOPS IN CONTACT
// under it (tacpad_apps' panelTic keeps it under the strip's real bottom), map
// tools under that and the reader below. The who-is-talking chip right of the
// rail at the top, APS under it. [] = not built on the tablet: the tiles have
// their own row, and ON BOARD replaces the squad rail on the vehicle tablet.
#define TABLET_RAIL [0.006, 0.010, 0.2493, 0.62]
#define TABLET_TALK [0.2613, 0.010, 0.17, 0.04]
#define TABLET_APS [0.2613, 0.070, 0.24, 0.30]
#define TABLET_TOOLSBTN [0.6934, 0.010, 0.0722, 0.04]
#define TABLET_SETTINGS [0.7696, 0.010, 0.0722, 0.04]
#define TABLET_ADMIN [0.8458, 0.010, 0.0722, 0.04]
#define TABLET_HIDE [0.9220, 0.010, 0.0722, 0.04]
#define TABLET_TIC [0.6934, 0.060, 0.3006, 0.068]
#define TABLET_TOOLS [0.6934, 0.130, 0.3006, 0.15]
#define TABLET_READER [0.6934, 0.290, 0.3006, 0.69]
#define TABLET_PLACES_COMMON ["tiles", []], ["aps", TABLET_APS], ["toolsbtn", TABLET_TOOLSBTN], ["settings", TABLET_SETTINGS], ["admin", TABLET_ADMIN], ["hide", TABLET_HIDE], ["tic", TABLET_TIC], ["tools", TABLET_TOOLS], ["reader", TABLET_READER]
#define TABLET_PLACES [TABLET_PLACES_COMMON, ["squad", TABLET_RAIL], ["onboard", []]]
#define TABLET_PLACES_VEHICLE [TABLET_PLACES_COMMON, ["squad", []], ["onboard", TABLET_RAIL]]
// THE RIGHT COLUMN STACKS FROM REAL BOTTOMS (FUNC(tabletStack)): the places
// above are where each panel is built, and the panels then fit to their type
// size, so map tools go under TIC's real bottom and the reader under the tools',
// this much air between them, in fractions of the map area.
#define TABLET_STACK_GAP 0.010
// The panels of the button strip at the top of the column.
#define TABLET_STRIP ["toolsbtn", "settings", "admin", "hide"]
// The talking chip's text size, as a multiple of the shell's body size.
#define TABLET_TEXT_TALK 0.8

// ON BOARD: a seat's role from fullCrew, as the rail prints it. A turret that
// is a person turret (firing from vehicle) is a passenger, not a gunner.
#define SEAT_ROLES [["driver", "DRV"], ["commander", "CMDR"], ["gunner", "GNR"], ["turret", "GNR"], ["cargo", "PAX"]]
#define SEAT_PAX "PAX"
#define SEAT_ORDER ["CMDR", "DRV", "GNR", SEAT_PAX]
// ON BOARD's columns, as fractions of the rail's width: the name ends at the
// first, the seat at the second, the talk flag takes the rest. Text at the tile
// band's size, as the squad rail sets it; the status icon is this much of a row.
#define ONBOARD_NAME_END 0.58
#define ONBOARD_SEAT_END 0.78
#define ONBOARD_TEXT 0.7
#define ONBOARD_ICON_ROW 0.62
// The scrolling body's bar, in pixels, which the flag column stops short of.
#define ONBOARD_SCROLL_PX 14
// Health under which a man reads wounded, in percent - the squad rail's line.
#define ONBOARD_WIA_PCT 75
// The squad rail's medical icons, so the two rails read the same.
#define ICON_OK QPATHTOEF(tacpad_apps,data\medical\ok_green.paa)
#define ICON_WIA QPATHTOEF(tacpad_apps,data\medical\bleeding_red.paa)
#define ICON_UNCON QPATHTOEF(tacpad_apps,data\medical\unconscious_white.paa)
#define ICON_KIA QPATHTOEF(tacpad_apps,data\medical\dead.paa)

// A man's state on board, as FUNC(vehicleSeats) reads it and both the ON BOARD
// rail (as an icon) and VEHICLE STATUS (as a word) draw it.
#define CREW_OK "OK"
#define CREW_WIA "WIA"
#define CREW_UNCON "UNCON"
#define CREW_KIA "KIA"
#define CREW_ICONS [[CREW_OK, ICON_OK], [CREW_WIA, ICON_WIA], [CREW_UNCON, ICON_UNCON], [CREW_KIA, ICON_KIA]]
// Worst first, for VEHICLE STATUS's hurt passengers.
#define CREW_SEVERITY [CREW_KIA, CREW_UNCON, CREW_WIA, CREW_OK]

// VEHICLE STATUS (FUNC(appVehicle)): the vehicle tablet's own app. Registered
// with the shell only while the vehicle tablet is the host (FUNC(onLoad) /
// FUNC(onUnload)), so the large and UAV tablets, the phone and the native map
// never have it - not as a tile, not on an F-key, not in the arrows' ring.
#define VEHICLE_APP "vehicle"
#define VEHICLE_APP_TITLE "VEHICLE STATUS"
// The page's width, as a fraction of the map area; its height is measured off
// its rows, at most the whole map area. Rows kept back for the header strip
// and the air under the last row.
#define VEHICLE_APP_W 0.96
#define VEHICLE_APP_SPARE_ROWS 3.5
// The three columns, as fractions of the body: DAMAGE + FUEL, AMMUNITION +
// COUNTERMEASURES, APS + RF SET + CREW.
#define VEHICLE_COLUMNS [0.33, 0.37, 0.30]
// Seconds between redraws while it is open; it stops when it closes.
#define VEHICLE_APP_TICK 2
// A section head is a row, its 2 px rule and a little air; a gap half a row.
#define VEHICLE_HEAD_ROWS 1.3
#define VEHICLE_GAP_ROWS 0.5
// Type sizes, as multiples of the shell's body size.
#define VEHICLE_TEXT_HEAD TEXT_LABEL
#define VEHICLE_TEXT_ROW TEXT_BODY
#define VEHICLE_TEXT_STRIP TEXT_TITLE
// A bar row: the label ends, the bar runs and the value starts at these
// fractions of the column; the bar is this much of the row tall.
#define VEHICLE_BAR_LABEL_END 0.30
#define VEHICLE_BAR_END 0.74
#define VEHICLE_BAR_ROW 0.42
// The strip's callsign and a section head's title take this much of the
// width; the speed and the head's right label the rest.
#define VEHICLE_STRIP_SPLIT 0.6
#define VEHICLE_HEAD_SPLIT 0.6
// A plain row's left text ends here; a magazine row is indented one pad more.
#define VEHICLE_ROW_SPLIT 0.62
#define VEHICLE_INDENT_PADS 3

// A LINE'S TONE. Green and amber are the theme's fixed swatches; red is the
// accent, which is only red on some schemes (tan on the default JMSB NIGHT,
// lime on OLIVE) - so red is never a hue alone. TONE_ALERT is not a theme
// token: FUNC(vehicleColumn) draws it as an inverted block, the accent filled
// behind the value and the value in the ground colour, the way the tile band
// draws "alert", and the value carries a word as well. Swatch tones are fills
// only - a small square beside an ink value, a filled bar - never text.
#define TONE_OK "swatchGreen"
#define TONE_WARN "swatchYellow"
#define TONE_ALERT "alert"
// The swatch square beside a value, and the alert block behind one, as
// fractions of a row's height.
#define VEHICLE_SWATCH_ROW 0.42
#define VEHICLE_BLOCK_ROW 0.82
// The words a red value carries.
#define WORD_DAMAGE_ALERT "CRIT"
#define WORD_FUEL_ALERT "LOW"
#define WORD_EMPTY "EMPTY"

// DAMAGE BY PART: getAllHitPointsDamage's names, lower case, sorted into
// groups by the first group whose fragment a name contains - so the commander's
// sight (hitcomgun) is OPTICS before GUN could claim it. The last group's ""
// takes whatever is left. Lights (and the engine's own # names) are not parts.
#define DAMAGE_GROUPS [ \
    ["HULL", ["hithull", "hitbody"]], \
    ["ENGINE", ["engine"]], \
    ["FUEL", ["fuel"]], \
    ["OPTICS", ["hitcom", "optic", "sight", "periscope"]], \
    ["TURRET", ["turret"]], \
    ["GUN", ["gun"]], \
    ["TRACKS", ["track"]], \
    ["WHEELS", ["wheel"]], \
    ["ROTORS", ["rotor"]], \
    ["AVIONICS", ["avionics", "missiles"]], \
    ["CONTROLS", ["hydraulic", "aileron", "rudder", "elevator", "transmission", "starter", "winch"]], \
    ["ARMOUR", ["era", "slat"]], \
    ["GLASS", ["glass"]], \
    ["OTHER", [""]] \
]
#define DAMAGE_SKIP ["light", "#"]
// Damage at which a part reads amber, and red.
#define DAMAGE_WARN 0.25
#define DAMAGE_ALERT 0.75

// FUEL. Below these it reads amber, then red.
#define FUEL_WARN 0.25
#define FUEL_ALERT 0.1
// THE RANGE IS MEASURED, NOT CONFIGURED: fuel burnt over ground covered since
// the last fill (FUNC(vehicleFuel)). It is given once this much fuel is gone
// over this many metres; a fuel rise of more than the epsilon is a refill.
#define FUEL_SAMPLE_MIN 0.01
#define RANGE_SAMPLE_MIN_M 500
#define FUEL_REFILL_EPS 0.005
#define METRES_PER_KM 1000

// COUNTERMEASURES: a magazine's ammunition simulation says what it is.
#define SIM_FLARE ["shotcm"]
#define SIM_SMOKE ["shotsmoke", "shotsmokex"]
// A vehicle smoke launcher's ammunition is shotCM like a flare's, so the
// launcher that takes the magazine (or the ammo's own muzzle effect) is what
// tells them apart.
#define SMOKE_LAUNCHER_WEAPON "SmokeLauncher"
#define SMOKE_LAUNCHER_EFFECT "smokelauncher"
// The driver's seat is turret [-1] to magazinesAllTurrets; on an aircraft it
// is the pilot's, with the guns, pylons and flares that come with it.
#define TURRET_DRIVER [-1]
#define TURRET_LABEL_DRIVER "DRIVER"
#define TURRET_LABEL_PILOT "PILOT"
#define VEHICLE_KIND_AIR "Air"

// APS, read off the vehicle (jmfsb_aps): its "no fit" value.
#define APS_FIT_NONE "NONE"


// Devices drawn with the same screen size, frames however different
// (FUNC(layout)): each pair gets the smaller of the two screens.
#define SCREEN_MATCH [["uav", "large"]]
// The engine trait that makes a player the UAV operator, and the tablet he gets.
#define UAV_TRAIT "UAVHacker"
#define UAV_DEVICE "uav"
#define LARGE_DEVICE "large"
// THE RDC (user, 2026-10-30: "make an rdc"): Persistent Systems' Rugged
// Display Controller, the MPU5's chest screen - a GPS-slot item like the phone
// (its walking view sits where the phone's does) that is also the tablet the
// carrier opens: a 16:9 screen, A B X Y for F1-F4, the two sticks for the
// arrows. Its frame is the MPU5 asset's own paint (tools/gen_rdc_src.py).
#define RDC_DEVICE "rdc"
// Which frame the tablet wears (jmfsb_devices_tabletFrame; user, 2026-10-21:
// "a way to toggle between the large and uav tablet"): the carried RDC, else
// the UAV skill's choice, or any frame outright.
#define TABLET_FRAME_AUTO "auto"
#define TABLET_FRAME_IDS [TABLET_FRAME_AUTO, LARGE_DEVICE, UAV_DEVICE, RDC_DEVICE]
#define TABLET_FRAME_NAMES ["Auto (carried RDC, else UAV skill decides)", "Large tablet", "UAV tablet (grips)", "RDC (MPU5 chest screen)"]

// DRONE CONTROL WITHOUT A UAV TERMINAL (FUNC(uavControl); user, 2026-10-20:
// the vanilla terminal is out of the arsenal). The net a drone is flown over
// and the quality below which control is lost - tacpad_apps' RADIO_NET_DATA
// and DRONE_LINK_LOST, the same numbers (docs/DESIGN_RF.md, drones).
#define UAV_LINK_NET "DATA"
#define UAV_LINK_LOST 0.2
// RF's "cannot say" (tacpad_apps' QUALITY_UNKNOWN): an unknown link does not
// block, a lost one does.
#define UAV_QUALITY_UNKNOWN -1
// How often the link and the seat are checked, in seconds.
#define UAV_TICK 0.5
// The view the drone is put in for each seat, and the player's fallback.
#define UAV_VIEW_DRIVER "INTERNAL"
#define UAV_VIEW_GUNNER "GUNNER"
// The way out from inside the drone (the tablet key does it too), and its
// place in the action menu.
#define UAV_RELEASE_TITLE "Release drone control"
#define UAV_RELEASE_PRIORITY 0
#define UAV_NOTIFY_TITLE "DRONES"
// DRONE ORDERS (FUNC(uavOrder)): what may be ordered, run where the drone's
// group is local. GO TO and RTB fly at the drone's height - this floor when
// it is sitting on the ground (m) - and a LOITER circle turns this way.
#define UAV_ORDERS ["orbit", "goto", "rtb", "lase"]
// remoteExec target of the server: a client's drone order goes there to be
// checked before it is sent on to the crew (review S7).
#define SERVER_OWNER 2
#define UAV_ALT_MIN 50
#define UAV_LOITER_TYPE "CIRCLE_L"
// RTB on an airframe that can set down (a helicopter-type drone): it lands
// where the MOVE ends. The statement runs only on the group's own machine.
#define UAV_LAND_KIND "Helicopter"
#define UAV_LAND_STATEMENT "if (local this) then {(vehicle this) land 'LAND'}"
// LASE: a laser designator is a turret weapon whose magazine's ammo simulates
// "laserDesignate", or a weapon of the engine's two designator families. The
// turret is given this long to slew onto the point before the designator is
// switched on (s). The driver's own weapons are turret [-1].
#define UAV_LASER_SIM "laserDesignate"
#define UAV_LASER_BASES ["Laserdesignator_mounted", "Laserdesignator"]
#define UAV_LASE_DELAY 1
#define UAV_DRIVER_TURRET [-1]
// RTB's home, in FUNC(uavHome)'s words.
#define UAV_HOME_LAUNCH "LAUNCH POINT"
#define UAV_HOME_STAGING "STAGING"
#define UAV_HOME_OPERATOR "OPERATOR"
// The walking view's map zoom is the player's: jmfsb_devices_phoneZoom.
// The player's own marker on that map is jmfsb_bft's, like everyone else's:
// the extra tan man icon this addon drew over it is gone (user, 2026-10-22:
// "you added a second icon over the bft icon, remove the tan one").

// THE WALKING VIEW: the phone and the side devices, as a title layer rather
// than a dialog - read-only, over the world, up while the item is assigned.
// A title layer takes no clicks and sits over everything, so it is taken DOWN
// whenever a dialog or the map is up (see FUNC(overlayTick)), and down at
// mission end, because a named layer outlives the mission on its own.
#define IDD_OVERLAY 8980
#define IDC_OVERLAY_GROUND 8981
#define IDC_OVERLAY_MAP 8982
#define IDC_OVERLAY_FRAME 8983
// The call strip (rings, a live call, quick add) and the grid readout, both
// over the map: there is no status row or notification line any more (user,
// 2026-10-21).
#define IDC_OVERLAY_CALL 8985
// THE STATUS ROW (back 2026-10-21: "more like your old top bar ... minus" the
// notification line): NET (the custom channels still available, %; user: "no
// net number", "reverse the % to available"), MESH, JAM, GPS (the grid),
// DRONES, MSG. FIRES and BATT went: placeholders that only ever said --.
// SEVEN WITH BATT (user, 2026-10-30: "the battery % on the tablet and phone
// display needs to work"), now that RF runs the batteries down: the lowest
// of the player's sets as RF published it (jmfsb_rf_batteries), amber at
// this share and red at this one; -- without a set, like any other cell.
#define OVERLAY_STATUS_CELLS 7
#define BATT_ICON "BATT"
#define BATT_WARN_K 0.2
#define BATT_ALERT_K 0.05
#define IDC_OVERLAY_CELL(n) (9030 + (n))
#define IDC_OVERLAY_SQUAD 8986
#define IDC_OVERLAY_SQUAD2 8987
#define IDC_OVERLAY_TALK 8988
// One cell per voice net the player is on (TEAM, C2, A2G, VEH, CALL, a held
// key's net) - eight at most. Each net cell is three controls: the outline
// under, the label inset over it, and the small ear tag (L / B / R).
#define OVERLAY_NET_CELLS 8
#define IDC_OVERLAY_NET(n) (8990 + (n))
#define IDC_OVERLAY_NETEDGE(n) (9000 + (n))
#define IDC_OVERLAY_NETRX(n) (9010 + (n))

// The phone's size is the player's (jmfsb_devices_phoneFill); the side devices' too.
// Air between the body and the edge of the safe zone it sits against.
#define OVERLAY_MARGIN 0.01
// Seconds between redraws. The rows are a glance, not a clock.
#define OVERLAY_TICK 0.5

// THE SCREEN IN DESIGN UNITS (docs/DESIGN_PHONE_WALKING.md and
// DESIGN_SIDE_DEVICES.md, "2x units"). Every row is its design height over
// the design screen's height, so the rows keep the drawn proportions at any
// size. Phone: 1030 x 440, landscape. Side devices: one shared 600 x 1000
// portrait screen.
#define PHONE_DESIGN_W 1030
#define PHONE_DESIGN_H 440
// Rows as tall as what is in them (user, 2026-10-21: the status bar and the
// net bar "too tall"): a status cell holds one line of text with its gutters
// (PHONE_ROW_STATUS is one row of cells; the phone has two, see
// STATUS_LAYOUT_LANDSCAPE); a net chip is one text line, its row the chip
// and a gutter.
#define PHONE_ROW_NETS 32
#define PHONE_ROW_STATUS 34
#define PHONE_NET_CELL_H 26
// The squad list's width, top left over the map.
#define PHONE_LIST_W 210
#define SIDE_DESIGN_W 600
#define SIDE_DESIGN_H 1000
#define SIDE_ROW_SQUAD 90
#define SIDE_ROW_NETS 120
#define SIDE_ROW_STATUS 70
#define SIDE_NET_CELL_H 32
// Nets on a portrait screen: two columns (2 x 3 in the design).
#define NET_COLS_PORTRAIT 2
// THE NET ROW (notes, 2026-10-30): six equal cells across the full width
// whatever the count, an empty one a dim outline; the cells this many screen
// pixels tall on the tablet, the phone and a portrait screen; the tablet's
// legend, in a tooltip over the row.
#define NET_ROW_CELLS 6
// The phone's one row holds four, not six (user, 2026-10-31: "on the phone
// change radio chips to 4"): each cell wider, its name whole.
#define NET_ROW_CELLS_PHONE 4
#define NET_CELL_PX_TABLET 40
#define NET_CELL_PX_PHONE 38
#define NET_CELL_PX_PORTRAIT 34
#define TABLET_NET_LEGEND "Press a net to make it active - numpad 1-5 select a net - Ctrl + 1-5 mute it"
// The GLOBAL cell is the game VON's Global channel: only while that is the
// voice system (the fallback; LiveKit is the voice, 2026-10-31).
#define VOICE_SYSTEM_VON "von"
// The net row with no game voice here (jmfsb_voice_system "none": the
// server's voice cannot run on this machine).
#define TEXT_VOICE_UNAVAILABLE "VOICE UNAVAILABLE"
// STATUS CELLS PER ROW, left to right then down, the cells of a row equal
// shares of the content's width. The phone's seven in one row ran into each
// other (user, 2026-10-30: "way too close together"): two rows now, four
// then three; a portrait screen keeps its three rows of three. A cell whose
// text is wider than its inside is set smaller by the measured ratio
// (ctrlTextWidth, FUNC(overlayDraw)) - never guessed.
#define STATUS_LAYOUT_LANDSCAPE [7]
#define STATUS_LAYOUT_PORTRAIT [3, 3, 3]
// THE DEVICE CLASSES (notes, 2026-10-30: "rows switch on class, not device
// name"): CfgJmfsbDevices deviceClass, FUNC(deviceClass). The walking view's
// squad list and talking box sit on a wash of the ground this opaque; a
// portrait screen's map is this share of its height.
#define DEVICE_CLASS_FULL "full"
#define DEVICE_CLASS_LANDSCAPE "landscape"
#define DEVICE_CLASS_PORTRAIT "portrait"
#define OVERLAY_WASH_ALPHA 0.85
#define OVERLAY_MAP_PORTRAIT_K 0.44
// Squad list below the map on a portrait screen: two columns of three.
#define SQUAD_ROWS_PORTRAIT 3
#define SQUAD_COLS_PORTRAIT 2
// Rows over the map on the phone, at most.
#define SQUAD_ROWS_LANDSCAPE 10
// Gutter, type and line height, and the who-is-talking chip's width, in
// design units.
#define DESIGN_GAP 6
#define DESIGN_TEXT 20
#define DESIGN_LINE 26
#define DESIGN_TALK_W 300
// Every device's header bar opens with this (FUNC(tabletBar), FUNC(overlayDraw)).
#define DEVICE_BRAND "TAC//APP"
// The ACE self-interaction icon for the tablets: the JMSB emblem the Staging
// Zone menu wears (user, 2026-10-21: "the same icon as staging zone").
#define TABLET_ACTION_ICON QPATHTOEF(media,images\Icons\jmfsbicon.paa)
// Shown in place of the grid while the GPS has no fix (jmfsb_ew_fnc_gpsState).
#define GRID_NO_FIX "NO FIX"
#define GPS_STATE_NOFIX "NO FIX"
#define GPS_STATE_SUSPECT "SUSPECT"
// Grid digits: an 8 or 10 figure grid (jmfsb_devices_gridDigits), cut from
// the ten-figure one; digits per axis are half.
#define GRID_DIGIT_CHOICES [8, 10]
#define GRID_DIGIT_NAMES ["8 figures", "10 figures"]
#define GRID_AXIS_FULL 5
// THE WALKING VIEW'S READABILITY (user, 2026-10-21: the side devices "are
// hard to read"). A portrait screen's rows sit inside the screen hole by this
// share of the hole's shorter side, the same number of pixels on all four
// sides, the ground showing round them as the screen's border, clear of the
// corner bumpers (user, 2026-10-21: "corners touching the frame"; 18 design
// units was 8.7 px). Text is raised to at least this fraction of the safe
// zone's height, at most this many times the design's own size, and never so
// far that the map keeps less than this share of the screen. A cell's text
// never outgrows this share of its height.
#define OVERLAY_INSET 0.05
// THE PHONE'S BORDER IS ONE PIXEL (user, 2026-10-30: "the border should be
// 1px, give the rest of the space back to the screen"; it was 0.05 of the
// hole's shorter side at the sides, 13 px on a 260 px screen, and 0.02 top
// and bottom). The rows stand this many screen pixels in from the hole on
// all four sides. The frame's corner guards still lie over the screen's
// corners (tools/gen_devices.py, the rubber kept); the cells' text is
// centred, so it stays clear of the lobes.
#define OVERLAY_BORDER_PX 1

#define OVERLAY_TEXT_MIN 0.015
#define OVERLAY_TEXT_SCALE_MAX 1.6
#define OVERLAY_MAP_MIN 0.4
// Absent sources and muted nets: the ink at this alpha. Was 0.42, which read
// as nothing over a bright map.
#define OVERLAY_DIM_ALPHA 0.6
// A status cell's text never outgrows this share of its height.
#define OVERLAY_CELL_TEXT_FIT 0.8
// The widest a net cell gets on the phone's one row, in design units, so a
// single net is a chip rather than a bar from bezel to bezel.
#define NET_CELL_MAX_W 260
// A net cell's outline, in pixels - the net's state, so thick enough to read
// (user, 2026-10-21: "put net state as a color around the net chips").
#define NET_EDGE_PX 3
// A net cell reads "<N> <name>", N its numpad select key; the design caps the
// name at ten characters.
#define NET_NAME_MAX 10
// The outline's colour from the net's quality (jmfsb_voice_fnc_netQuality):
// green at or above this, amber between it and 0 (weak or jammed), red at 0.
#define NET_QUALITY_GOOD 0.5
// The tag in front of a net cell while the player talks on it (red cell).
#define NET_TX_TAG "TX"
// The leaders' GLOBAL button on the tablet's net row: its width in design
// units, and its label off / on.
#define TABLET_NET_GLOBAL_W 120
#define GLOBAL_LABEL_OFF "GLOBAL"
#define GLOBAL_LABEL_ON "ON GLOBAL"
// SELECT NET 1-9 keybinds (user, 2026-10-21): the first five on numpad 1-5
// (user, 2026-10-30: "1-5 are radio nets"), the rest unbound by default -
// numpad 6-9 are the device keys.
#define NET_SELECT_KEYS 9
#define NET_SELECT_DEFAULTS [DIK_NUMPAD1, DIK_NUMPAD2, DIK_NUMPAD3, DIK_NUMPAD4, DIK_NUMPAD5]

// Status icon states.
#define STATE_OFF 0
#define STATE_OK 1
#define STATE_WARN 2
#define STATE_ALERT 3
// Percent of jamming at which the JAM cell turns red.
#define JAM_ALERT_PCT 50
// Percent of the custom channels still free at or below which NET warns.
#define CHANNEL_WARN_PCT 20
#define PERCENT 100
// The jamming addon's domain for the JAM cell.
#define JAM_DOMAIN_ANY "any"

// RF: the data net every node carries, which the squad list's link flags read.
#define MESH_NET "DATA"

// The squad list's flags and the talking chip.
#define VOICE_DIRECT 1
#define VOICE_RADIO 2
#define TALK_HOLD 4

// GAME VOICE (docs/DESIGN_VOICE.md), read through jmfsb_voice's API: a call's
// states and the routine priority (jmfsb_voice_fnc_calls), the net kinds the
// rows treat apart (jmfsb_voice_fnc_nets), and the ear words in their L > B > R
// order. NET_KIND_RING is ours: the RING cell a ringing call gets before it
// has a call net.
#define CALL_RINGING "ringing"
#define CALL_LIVE "live"
#define CALL_OUTGOING "outgoing"
#define CALL_ROUTINE "ROUTINE"
#define CALL_WARNING "warning"
// The call's picture (jmfsb_tacpad_apps_fnc_callFeed): what a man's camera
// sends, public on him as jmfsb_tacpad_apps_callCam, the surface it renders to
// and its resolution. FUNC(callWindow) floats it over the screen: its width as
// a share of the map area on the tablet and on the walking view, its height to
// width in pixels, its caption's share of its height, the gap to the map
// area's edge (px). Corners count clockwise from top left (0 top left, 1 top
// right, 2 bottom right, 3 bottom left): the tablet's arrows step it round
// all four (FUNC(callCorner), kept in the player's profile) from bottom left;
// on the walking view it sits top right.
#define CALL_CAM_FACE "face"
#define CALL_CAM_VIEW "view"
#define CALL_FEED_RTT QEGVAR(tacpad_apps,callFeed)
#define CALL_FEED_RES 512
#define CALL_WINDOW_SHARE 0.3
#define CALL_WINDOW_SHARE_SMALL 0.45
#define CALL_WINDOW_ASPECT 0.75
#define CALL_WINDOW_CAPTION 0.16
// The caption's type against the caption's height.
#define CALL_WINDOW_CAPTION_FONT 0.8
// The window's controls: the ground, the picture, the caption (made last).
#define CALL_WINDOW_PARTS 3
#define CALL_WINDOW_GAP_PX 8
#define CALL_CORNERS 4
#define CALL_CORNER_DEFAULT 3
#define CALL_CORNER_SMALL 1
// What jmfsb_voice_callState's other states say on the notification line (the
// voice README: "warning", "ended" and the failure reasons), and how long (s).
#define CALL_STATE_WORDS [[CALL_WARNING, "priority warning - a FLASH call is taking this slot"], ["ended", "ended"], ["noRoute", "no route - CALL BACK is available"], ["busy", "busy - CALL BACK is available"], ["noAnswer", "no answer - CALL BACK is available"], ["declined", "declined"], ["bumped", "bumped by a FLASH call"], ["dropped", "dropped - no route"], ["refused", "nobody in reach on DATA"], ["notOwner", "only the call's owner can add people"]]
#define CALL_STATE_HOLD 8
#define VOICE_KIND_DIRECT "direct"
#define VOICE_KIND_CALL "call"
#define VOICE_KIND_VEH "veh"
#define NET_KIND_RING "ring"
#define EARS ["L", "B", "R"]
#define SECONDS_PER_MINUTE 60

// THE SMALL DEVICES' RADIO APP (FUNC(radioApp), FUNC(radioDraw)): its tabs, the
// group chips on CALLS ([group id as jmfsb_tacpad_apps_fnc_radioGroup takes
// it, chip]), the roles MANAGE opens to (jmfsb_tacpad_apps_fnc_radioRole), and
// the tab keys' two codes for FUNC(radioKey) - past the six frame keys.
#define RADIO_APP_TABS ["nets", "calls", "manage"]
#define RADIO_CHIPS [["team", "+ TEAM"], ["sl", "+ SLs"], ["rto", "+ RTOs"], ["medic", "+ MEDICS"], ["hq", "+ HQ"]]
#define MANAGE_ROLES ["TL", "SL", "RTO", "ADMIN"]
#define RADIO_TAB_PREV 6
#define RADIO_TAB_NEXT 7
// The echo test's row on CALLS (jmfsb_adapter_livekit_fnc_echo): its data,
// and the test's states as jmfsb_adapter_livekit_fnc_echoState gives them
// ("" no extension: no row).
#define RADIO_ROW_ECHO "echo"
#define ECHO_IDLE "idle"
#define ECHO_JOINING "joining"
#define ECHO_LIVE "live"
// Glyphs the rows draw, written as numbers so the file stays ASCII: the
// talking box's dot and the arrows of the cursor and the net row.
#define DOT_TEXT (toString [9679])
#define ARROW_UP_TEXT (toString [9650])
#define ARROW_DOWN_TEXT (toString [9660])
// A man past this much damage reads wounded where ACE medical is absent.
#define WOUNDED_DAMAGE 0.1
// The team colours, as jmfsb_bft draws them, for the member numbers.
#define TEAM_HTML [["MAIN", "#ffffff"], ["RED", "#e53835"], ["GREEN", "#42a147"], ["BLUE", "#1f87e6"], ["YELLOW", "#fcd936"]]

// Colours (DESIGN_PHONE_WALKING.md, "Colours").
#define COLOUR_BAR [0.125, 0.118, 0.114, 1]
#define COLOUR_BAR_SCRIM [0.125, 0.118, 0.114, 0.8]
#define COLOUR_TEXT [0.953, 0.949, 0.949, 1]
#define COLOUR_DIM [0.663, 0.663, 0.635, 1]
#define COLOUR_ALERT [1, 0.337, 0.235, 1]
#define COLOUR_WARN [0.85, 0.65, 0.15, 1]
#define COLOUR_NET_OK [0.263, 0.627, 0.278, 1]
#define COLOUR_NET_BAD [0.898, 0.224, 0.208, 1]
#define COLOUR_RING [0.125, 0.118, 0.114, 0.55]
// The talk flags as colours rather than markup: TX is the alert red, VOX the
// same magenta as HTML_VOX.
#define COLOUR_TX COLOUR_ALERT
#define COLOUR_VOX [0.851, 0.2, 0.851, 1]
#define HTML_TX "#ff563c"
#define HTML_OK "#43a047"
#define HTML_VOX "#d933d9"
#define HTML_DIM "#a9a9a2"
#define HTML_TEXT "#f3f2f2"

// The range rings on the map, in metres, and the blank texture their labels
// ride on.
#define RING_RADII [25, 50]
#define RING_TEXT_SIZE 0.03
#define BLANK_ICON "#(argb,8,8,3)color(0,0,0,0)"

// Displays the view hides under: ACE arsenal, the vanilla arsenal and the
// vanilla spectator (the latter two keep themselves in uiNamespace by class).
#define IDD_ACE_ARSENAL 1127001
#define IDD_EG_SPECTATOR 60492
// The camera view of a sight or scope - the walking view gets out of the way.
#define CAMERA_VIEW_SIGHT "GUNNER"

// ST_CENTER for the net cells; the engine's own define lives in a header
// whose IDC_ names would collide with ours.
#ifndef ST_CENTER
    #define ST_CENTER 2
#endif

// THE TABLET FRAME'S FOUR SOFT KEYS (jmfsb_devices_keyF1..F4): the apps a key
// may open, and the names Addon Options and SETTINGS > DEVICE KEYS show. The
// apps jmfsb_tacpad_apps registers, written out because registration happens
// in postInit and settings are declared before that. An id that is not
// registered in a given mission opens nothing. VEHICLE STATUS opens only on
// the vehicle tablet (FUNC(onLoad) registers it there alone).
#define SOFT_KEY_IDS ["", "comms", "squad", "radio", "weather", "timer", "drones", "jam", "scanner", "hack", "intel", "support", "settings", VEHICLE_APP, "medic"]
#define SOFT_KEY_NAMES ["None", "TAC//MSG", "Squad", "Radio", "Weather", "Timer", "Drones", "Jamming", "Scanner", "Hack", "Intel", "Support", "Settings", "Vehicle status (vehicle tablet only)", "Medic (CLS and Medic only)"]

// THE WALKING VIEW'S SIX FRAME BUTTONS - F1-F4, LEFT, RIGHT, as printed on the
// phone and side frames (CfgJmfsbDevices keys[] order). The layer is a title
// layer and takes no mouse, so each button is a CBA keybind - numpad 1-4, 0
// and . by default, F1-F4 Alt + numpad 1-4 - firing what its setting
// (jmfsb_devices_buttonF1..Right) says, and only while the walking view is up
// (FUNC(overlayButton)). The same keybinds are the tablet frame's keys while
// the tablet is open (FUNC(keyDown)).
#define BUTTON_LABELS ["F1", "F2", "F3", "F4", "left", "right"]
#define BUTTON_KEYS [DIK_NUMPAD6, DIK_NUMPAD7, DIK_NUMPAD8, DIK_NUMPAD9, DIK_NUMPAD0, DIK_DECIMAL]
// What the on-screen hints call the six buttons: the numpad keys they are on
// (notes, 2026-10-30: "hints read 6 7 8 9, not F1-F4"). BUTTON_LABELS stay
// the keybind and setting ids.
#define BUTTON_HINTS ["6", "7", "8", "9", "0", "."]
// A PROFILE KEEPS THE FIRST DEFAULT IT SAW (user, 2026-10-31, the CONTROLS
// screenshot: Device button F1-F4 still on numpad 1-4, where the nets are,
// Open Tablet with no key). CBA writes a keybind's default into the profile
// (cba_keybinding registry) the first time it registers and never reads a
// changed default again, so a new default reaches new profiles only. Each
// entry: the action, the defaults earlier standards shipped, and today's -
// a stored bind that is one of the old defaults, or empty, becomes today's
// (XEH_postInit); a bind the player chose himself is kept.
#define CBA_KEYBIND_REGISTRY "cba_keybinding_registry_v3"
#define KEYBIND_NO_MODS [false, false, false]
#define KEYBIND_MIGRATIONS [ \
    [QGVAR(button_F1), [[DIK_NUMPAD1, KEYBIND_NO_MODS]], [DIK_NUMPAD6, KEYBIND_NO_MODS]], \
    [QGVAR(button_F2), [[DIK_NUMPAD2, KEYBIND_NO_MODS]], [DIK_NUMPAD7, KEYBIND_NO_MODS]], \
    [QGVAR(button_F3), [[DIK_NUMPAD3, KEYBIND_NO_MODS]], [DIK_NUMPAD8, KEYBIND_NO_MODS]], \
    [QGVAR(button_F4), [[DIK_NUMPAD4, KEYBIND_NO_MODS]], [DIK_NUMPAD9, KEYBIND_NO_MODS]], \
    [QGVAR(tabletKey), [[DIK_NUMPAD5, KEYBIND_NO_MODS], [DIK_NUMPAD8, KEYBIND_NO_MODS], [DIK_HOME, [false, true, false]]], [DIK_NUMPADENTER, KEYBIND_NO_MODS]], \
    [QGVAR(netSelect_6), [[DIK_NUMPAD6, KEYBIND_NO_MODS]], [KEY_NONE, KEYBIND_NO_MODS]] \
]
// THE NUMPAD STANDARD (user, 2026-10-30: "1-5 are radio nets, 6 7 8 9 are
// F1-F4, - is TIC, 0 and . are the arrows, / = no do not answer, * = yes or
// answer"; it replaces 2026-10-25's 1-6 nets / 7 8 9 functions).
//   1-5  pick net 1-5 (the chip number)   Ctrl + 1-5 mute / unmute that net
//   6 7 8 9  device F1-F4 (the walking view's jobs, the tablet frame's apps)
//   0  .  device arrows left / right
//   * answer / hang up (yes)   / decline (no)   - TROOPS IN CONTACT
//   + voice activation on/off   Enter open / close the tablet
// No default key, each rebindable: talk local (hold), radio volume, the
// RADIO app on the phone, its tabs, PTT 2-4, open channel NET / LOCAL,
// the call camera. The sign of it is "numpad" in tools/gen_signs.py.
#define KEY_NONE -1
// What FUNC(keyLabel) answers for a cleared bind and for no such bind.
#define KEY_LABEL_UNBOUND "UNBOUND"
#define KEY_LABEL_NONE "--"
// [shift, ctrl, alt]: the device keys are plain numpad 6-9 now (they were
// Alt + 1-4 while 1-6 were the nets).
#define BUTTON_MODS_F [false, false, false]
#define BUTTON_MODS_ARROW [false, false, false]
#define BUTTON_F_COUNT 4
#define NET_SELECT_MODS [false, false, false]
// Ctrl + the net's number mutes / unmutes it (user, 2026-10-25).
#define NET_MUTE_MODS [false, true, false]
#define TAB_MODS [false, false, false]
#define KEY_ANSWER DIK_MULTIPLY
#define KEY_DECLINE DIK_DIVIDE
#define KEY_VAD DIK_ADD
// The call camera FACE / VIEW (user, 2026-10-28): no default key, the numpad
// is full.
#define KEY_CALL_CAM KEY_NONE
// The rest of the numpad block: the tablet on Enter, the RADIO app on the
// carried device and its previous / next tab unbound. - is TROOPS IN
// CONTACT, which is jmfsb_tacpad_apps' own keybind.
// The incoming-call notification's accent (user, 2026-10-24).
#define RING_NOTIFY_COLOUR [0.9, 0.6, 0.2, 1]
#define KEY_TABLET DIK_NUMPADENTER
#define KEY_RADIO_APP KEY_NONE
#define KEY_TAB_PREV KEY_NONE
#define KEY_TAB_NEXT KEY_NONE
// What a button can do. First the voice keys of docs/DESIGN_VOICE.md, which
// are the defaults - F1 accept a call, F2 ear / quick add, F3 mute, F4 decline
// / hang up, the arrows the active net (FUNC(voiceAction)) - and the RADIO
// app; then the walking view's own actions, and the tablet - on an app when
// the id carries the prefix.
#define BUTTON_NONE ""
#define BUTTON_CALL_ACCEPT "callAccept"
#define BUTTON_EAR_QUICK "earQuickAdd"
#define BUTTON_MUTE "mute"
#define BUTTON_DECLINE "declineHangUp"
#define BUTTON_NET_PREV "netPrev"
#define BUTTON_NET_NEXT "netNext"
#define BUTTON_VOICE [BUTTON_CALL_ACCEPT, BUTTON_EAR_QUICK, BUTTON_MUTE, BUTTON_DECLINE, BUTTON_NET_PREV, BUTTON_NET_NEXT]
#define BUTTON_RADIO_APP "radioApp"
#define BUTTON_ZOOM_IN "zoomIn"
#define BUTTON_ZOOM_OUT "zoomOut"
#define BUTTON_EDGE_LEFT "edgeLeft"
#define BUTTON_EDGE_RIGHT "edgeRight"
#define BUTTON_HIDE "hide"
#define BUTTON_TABLET "tablet"
#define BUTTON_APP_PREFIX "app:"
#define BUTTON_IDS [BUTTON_NONE, BUTTON_CALL_ACCEPT, BUTTON_EAR_QUICK, BUTTON_MUTE, BUTTON_DECLINE, BUTTON_NET_PREV, BUTTON_NET_NEXT, BUTTON_RADIO_APP, BUTTON_ZOOM_IN, BUTTON_ZOOM_OUT, BUTTON_EDGE_LEFT, BUTTON_EDGE_RIGHT, BUTTON_HIDE, BUTTON_TABLET, "app:comms", "app:squad", "app:radio", "app:weather", "app:timer", "app:drones", "app:jam", "app:scanner", "app:hack", "app:intel", "app:support", "app:settings", "app:medic", "app:pointman", "app:jumpmaster"]
#define BUTTON_NAMES ["None", "Accept call (quick add: add)", "Ear for the active net (in a call: quick add)", "Mute the active net", "Decline or hang up (quick add: close)", "Active net left (quick add: previous)", "Active net right (quick add: next)", "RADIO app on this device", "Map zoom in", "Map zoom out", "Side device to the left edge", "Side device to the right edge", "Hide the walking view", "Open the tablet", "Tablet on TAC//MSG", "Tablet on Squad", "Tablet on Radio", "Tablet on Weather", "Tablet on Timer", "Tablet on Drones", "Tablet on Jamming", "Tablet on Scanner", "Tablet on Hack", "Tablet on Intel", "Tablet on Support", "Tablet on Settings", "Tablet on Medic (CLS and Medic only)", "Tablet on Point Man", "Tablet on Jumpmaster (squad leaders)"]

// A side device's edges; the first is where it sits for a new profile.
#define EDGES ["right", "left"]
// What the worn-device line in SETTINGS > DEVICES calls each walking device.
#define WALK_DEVICE_NAMES [["phone", "PHONE"], ["side", "SIDE"], ["side2", "SIDE 2"], [RDC_DEVICE, "RDC"]]
// The walking devices that sit bottom centre like the phone (the rest take an edge).
#define WALK_BOTTOM_DEVICES ["phone", RDC_DEVICE]
#define WALK_DEVICE_NONE "NONE"

// THE WALKING VIEW'S SLIDERS as SETTINGS > DEVICES steps them: the ranges
// initSettings.inc.sqf declares (kept as literals there so docs/SETTINGS.md
// prints them) and the step one press takes. A size or opacity reads as a
// percent, the zoom as a map scale to ZOOM_DECIMALS places, as Addon Options
// shows them. The walking-view zoom buttons take the same step.
#define PHONE_FILL_MIN 0.15
#define PHONE_FILL_MAX 0.5
// Three tenths of the screen's height, less 15 % (user, 2026-10-31: "make
// the phone 15% smaller").
#define PHONE_FILL_DEFAULT 0.255
#define SIDE_FILL_MIN 0.2
#define SIDE_FILL_MAX 0.8
#define FILL_STEP 0.05
#define FILL_DECIMALS 2
#define ZOOM_MIN 0.005
#define ZOOM_MAX 0.1
#define ZOOM_STEP 0.005
#define ZOOM_DECIMALS 3
#define OPACITY_MIN 0.4
#define OPACITY_MAX 1
#define OPACITY_STEP 0.05
// ---- THE TABLET SCREEN'S RECESS (2026-10-21) ---------------------------------
// The screen sits in a dark recess, the key column's panel colour (sampled
// from art/devices/large_frame.png). Every row is inset this many design px
// from the screen hole, so nothing draws to the bezel's edge. No light rim:
// "there is a light line around the screen that needs to go away" (user,
// 2026-10-21).
// MEASURED, NOT GUESSED (user, 2026-10-21: "use math"). On the frame texture
// (art/devices/large_frame.png, 2048 canvas px) the key column's panel edge
// stands 14 px outside its keys and each key's light rim is 5 px; the screen
// hole is 1729 px across and 1364 design units (TABLET_DESIGN_W), so one
// canvas px is 1364 / 1729 = 0.789 units. The screen's border is the panel's
// margin, 14 x 0.789 = 11 units, in design units so it scales with the
// device. (40 was too wide: "gap is too big".)
#define TABLET_RECESS 11
#define COLOUR_RECESS [0.149, 0.153, 0.157, 1]
// The recess band's corner pieces (FUNC(tabletChrome)): the row each fills
// (FUNC(tabletRows)) and its quarter-round texture (tools/gen_devices.py).
#define CORNER_PIECES [["cornerTL", QPATHTOF(data\corner_tl_ca.paa)], ["cornerTR", QPATHTOF(data\corner_tr_ca.paa)], ["cornerBL", QPATHTOF(data\corner_bl_ca.paa)], ["cornerBR", QPATHTOF(data\corner_br_ca.paa)]]
