#define COMPONENT fa_mediumcaliber
#define COMPONENT_BEAUTIFIED Future Ammunition - Medium Caliber
#include "\z\jmfsb\addons\fa_main\script_mod.hpp"
#include "\z\jmfsb\addons\fa_main\script_macros.hpp"

// Proximity tick for a tracked shell (s). The swept test covers the whole
// path flown since the last tick, so 20 Hz loses nothing a per-frame check
// would catch, and a burst of rounds costs a third as much.
#define TRACK_TICK 0.05
