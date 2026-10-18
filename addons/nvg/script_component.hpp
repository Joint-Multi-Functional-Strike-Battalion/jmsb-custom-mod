#define COMPONENT nvg
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_NVG
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_NVG
    #define DEBUG_SETTINGS DEBUG_SETTINGS_NVG
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// --- The tube mask (the "NVG full screen" client setting, when off) ---------
// currentVisionMode: 0 day, 1 image intensifier, 2 thermal. The mask rides the
// intensifier only, as ACE's own does.
#define VISION_MODE_NVG 1
#define IDD_MISSION 46
#define IDD_ZEUS 312

// ACE's own masks (ace_nightvision\data). The binocular one is what a goggle
// with no border of its own anywhere up its parents gets - ACE gives it to
// NVGoggles, the root of most of them.
#define MASK_DEFAULT "\z\ace\addons\nightvision\data\nvg_mask_binos_4096.paa"

// ACE's border geometry (ace_nightvision_fnc_refreshGoggleType): a picture
// BORDER_SIZE screen heights tall and 3:4 of that wide, centred, scaled by the
// zoom - at the default field of view ACE's own factor is MASK_ZOOM. ACE
// rescales it every frame as you zoom; this one stays at the default view,
// so nothing runs per frame.
#define MASK_BORDER_SIZE 3
#define MASK_ASPECT 0.75
#define MASK_ZOOM 1.12513
#define SCREEN_CENTRE 0.5
// ACE fades a border with no eye cups a little; eye cups draw it solid.
#define MASK_FADE_NO_EYECUPS 0.15
#define MASK_FADE_EYECUPS 0

// --- CBA's picture-in-picture scopes (FUNC(syncPipVision)) ------------------
// CBA optics' PiP camera and render target, and setPiPEffect's modes: normal,
// night vision, thermal (white hot) - currentVisionMode's 0, 1, 2 in the same order.
#define CBA_PIP_CAMERA "cba_optics_camera"
#define CBA_PIP_TARGET "cba_optics_rendertarget0"
#define PIP_NORMAL 0
#define PIP_NVG 1
#define PIP_TI 2
#define PIP_TICK 0.25
