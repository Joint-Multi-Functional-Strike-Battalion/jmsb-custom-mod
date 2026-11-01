#define COMPONENT notify
#define COMPONENT_BEAUTIFIED Notify
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#include "\z\jmfsb\addons\main\script_macros.hpp"

// Fixed slots rather than ctrlCreate: simpler, and the stack is never deeper
// than a player can read anyway. Overflow queues instead of growing the HUD.
#define SLOT_COUNT      6
#define HISTORY_MAX     60
#define IDC_SLOT(n)     (8300 + (n) * 10)
#define IDC_BAR(n)      (8301 + (n) * 10)
#define IDC_TEXT(n)     (8302 + (n) * 10)

#define TICK_INTERVAL   0.25    // sec between expiry / restack passes
#define SLIDE_TIME      0.2     // sec for a slot to move to its new row

// Type size at scale 1.0, as a fraction of the safe zone height. Everything
// else about a row - its height, its padding - is derived from this, so the
// panel grows with the text instead of clipping it. A fixed pixelGrid size in
// the config cannot do that: it ignores how big the row actually is, which is
// how the old notifications ended up looking like dots.
#define FONT_BASE       0.0165
#define ROW_LINES       2.7     // title + body + breathing room, in font heights
#define ROW_GAP         0.5     // between rows, in font heights

// The default accent (ember) and the server's machine id (FUNC(broadcast)).
#define NOTE_DEFAULT    [ARR_4(0.871,0.361,0.188,1)]
#define SERVER_OWNER    2
