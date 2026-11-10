#define COMPONENT range
#define COMPONENT_BEAUTIFIED Range
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_RANGE
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_RANGE
    #define DEBUG_SETTINGS DEBUG_SETTINGS_RANGE
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// Modes - the module's numbers.
#define MODE_TIMED      1
#define MODE_COUNT      2
#define MODE_RAMPAGE    3
#define MODES           [MODE_TIMED, MODE_COUNT, MODE_RAMPAGE]
#define MODE_NAMES      ["", "Pop-ups, timed", "Pop-ups, set number", "Rampage"]

// The pop-up target's animation and its two ends.
#define TARGET_ANIM     "terc"
#define TARGET_UP       0
#define TARGET_DOWN     1
// What the hit has to touch to count - not the stand.
#define TARGET_PARTS    ["target", "pole_bottom"]
// Off a running range a hit target comes back up after this, as the game's
// own targets do (unless the mission set nopop).
#define POPUP_DELAY     3

// The run's beat, seconds.
#define TICK            0.1
// Who hears the range's results - and who it warns about a shooter.
#define VICINITY        50

// Vanilla firing-drill sounds (CfgSounds).
#define SOUND_HIT       "Beep_Target"
#define SOUND_COUNT     "FD_Timer_F"
#define SOUND_START     "FD_Start_F"
#define SOUND_FINISH    "FD_Finish_F"

// Notification colours (jmfsb_notify).
#define NOTE_INFO       [0.761, 0.659, 0.471, 1]
#define NOTE_GOOD       [0.4, 0.702, 0.4, 1]
#define NOTE_BAD        [0.831, 0.267, 0.267, 1]
#define NOTE_TITLE      "Range"

// The ACE menu.
#define ACE_ICON        "\a3\ui_f\data\igui\cfg\simpletasks\types\target_ca.paa"
