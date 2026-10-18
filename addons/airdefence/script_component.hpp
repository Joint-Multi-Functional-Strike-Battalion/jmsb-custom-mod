#define COMPONENT airdefence
#define COMPONENT_BEAUTIFIED Air Defence
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_AIRDEFENCE
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_AIRDEFENCE
    #define DEBUG_SETTINGS DEBUG_SETTINGS_AIRDEFENCE
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// A TEMPORARY SYSTEM, on purpose. ALiVE places air defence itself and jmfsb's
// standing rule is to feed ALiVE rather than duplicate it - but ALiVE 3's
// version is not stable yet, so this stands in until it is. Nothing else is
// built on top of it and it is expected to be deleted, not grown.

// How the two kinds of commander are answered. A conventional commander -
// invasion or occupation - gets a radar cueing launchers set back from it. An
// asymmetric one gets men with MANPADS, because a guerrilla does not field a
// battery and a battery is not something players can quietly walk past.
#define AD_CONVENTIONAL ["invasion", "occupation"]

// Launchers stand off the radar the way a real battery does: far enough that
// killing the radar is a separate job from killing the launchers, near enough
// that they read as one site.
#define AD_LAUNCH_MIN   150
#define AD_LAUNCH_MAX   450

// A MANPAD team is a couple of men, not a squad - they are meant to be found
// on foot and dealt with, not fought through.
#define AD_TEAM_MIN     2
#define AD_TEAM_MAX     3

// The ring a MANPAD team is placed in around the objective it covers. Off the
// objective itself: a shooter sits where he can see the approach, not in the
// middle of the thing everyone is already looking at.
#define AD_TEAM_MIN_R   200
#define AD_TEAM_MAX_R   700

// Security on a battery: a fireteam, standing off the hardware. Out far enough
// that whatever kills the launchers does not kill the guards with them, close
// enough that they are guarding this site and not the next valley.
#define AD_SEC_MIN      4
#define AD_SEC_MAX      6
#define AD_SEC_MIN_R    60
#define AD_SEC_MAX_R    200
// Two security groups at most, on a battery or a base - a site is defended
// enough that walking on is not free, not a garrison a section must assault.
#define AD_SEC_GROUPS_MAX 2

// THE AA BASE (FUNC(moduleAABase)) - a site the mission maker put down by hand,
// laid out inside the module's own area. Every ring is a FRACTION of the area's
// radius, so a 300 m area and a 1 km area both read as one site.
//
// Below this the rings collapse onto the radar - the floor a tiny or unset
// area is lifted to.
#define AB_RADIUS_MIN       100
// Launchers on the outer ring: set back from the radar so killing the radar
// and killing the launchers are separate jobs.
#define AB_LAUNCH_INNER     0.5
// Guns on the inner ring, close in - they are point defence for the radar.
#define AB_GUN_INNER        0.15
#define AB_GUN_OUTER        0.4
// Guards stand off the hardware, across the whole area.
#define AB_GUARD_INNER      0.3
// Launcher and gun spacing - apart enough that one hit does not take two.
#define AB_LAUNCH_SEP       40
#define AB_GUN_SEP          25
// Footprints and clear ground: a SAM is a few metres across, a gun less.
#define AB_LAUNCH_FOOT      10
#define AB_GUN_FOOT         6
#define AB_CLEAR            12
#define AB_SLOPE            0.12
// CfgVehicles >> side, as the engine numbers it.
#define AB_SIDES            [east, west, independent]

// minutes between rearms when no Air Defence module set Rearm Every
#define AD_REARM_DEFAULT 10
