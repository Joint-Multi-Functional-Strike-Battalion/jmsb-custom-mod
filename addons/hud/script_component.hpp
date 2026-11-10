#define COMPONENT hud
#define COMPONENT_BEAUTIFIED HUD
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_HUD
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_HUD
    #define DEBUG_SETTINGS DEBUG_SETTINGS_HUD
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The suite's own drawing vocabulary and type scale - the HUD is the same design
// as the map screens, on a different surface.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// DIK_LBRACKET and friends. JMSB's macro header does not pull these in - an
// addon that wants a default keybind has to ask for them, and without it
// DIK_LBRACKET compiles as an undefined VARIABLE rather than a key code.
#include "\a3\ui_f\hpp\definedikcodes.inc"

#define IDD_HUD 8920
#define IDC_HUD_LEFT 8921
#define IDC_HUD_RIGHT 8922

// THE TWO SLOTS ARE THE VANILLA INFO PANELS' IDEA, borrowed deliberately: one
// readout a side, cycled with a key, rather than a wall of widgets. A player who
// wants two things on screen has two slots and has to choose, which is the
// constraint that keeps a HUD a HUD.
#define HUD_SLOT_LEFT 0
#define HUD_SLOT_RIGHT 1

// How big a slot is, in grid cells, lives with the grid itself - gui.hpp, where
// it is the vanilla Custom Info panel's own ten by ten. Two defines here said
// thirteen by nine, were read by nothing, and were the third number in the mod
// claiming to be the panel's size.

// How long the title layer lives before the engine drops it, and how often
// the mission renews it. The gap between them is the slack: the renewal
// only has to beat the expiry, and a mission that has stopped renews
// nothing - which is what keeps the HUD off the main menu.
// Kept SHORT deliberately. At twenty seconds the panel could still be on
// the main menu for twenty seconds after leaving a mission, which looks
// exactly like the bug it is meant to end. Five gives the one-second tick
// four chances to renew - enough slack for a stutter - and puts the panel
// out within five seconds of the mission stopping.
#define HUD_LAYER_LIFE 5
#define HUD_LAYER_RENEW 2

// BUILT ONCE, UPDATED IN PLACE (review P5 / R8). A readout no longer draws:
// it pushes draw ops onto a list, and FUNC(paint) turns the list into
// controls. Each op is [kind, args], where args are exactly the tacpad
// helper's arguments without the parent - so a rebuild is that helper,
// called as it always was, and the pixels cannot move.
#define HUD_OP_FILL "fill"
#define HUD_OP_FRAME "frame"
#define HUD_OP_TEXT "text"
#define HUD_OP_ICON "icon"

// The scanner sweep is read at most this often (seconds) by the HUD, unless
// its inputs - the player unit and whether he carries the set - change first.
// EFUNC(hacking,scannerRead) has its own two-second cache; this stops the HUD
// asking every second on top of it.
#define HUD_SWEEP_TTL 3
