#define COMPONENT vehicle
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written
// against, plus the notification colours and the logistics shorthand. Included
// AFTER jmfsb's macros so the #undef in there lands on the right definitions.
#include "\z\jmfsb\addons\diag\roomba_macros.hpp"

// No vehicle radio racks: they were ACRE's (addRadio / setRadio, removed with
// ACRE, DEC1 2026-10-31). Under game voice a vehicle is the VEH net.

// ST_CENTER, ST_LEFT and the pixel-grid defines the dialog geometry is written
// in. The mission got these from its own defines.hpp; a mod takes them from
// the game's own headers.
#include "\a3\ui_f\hpp\defineCommonGrids.inc"
#include "\a3\ui_f\hpp\defineResincl.inc"
