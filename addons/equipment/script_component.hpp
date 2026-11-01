#define COMPONENT equipment
#define COMPONENT_BEAUTIFIED Equipment

#ifdef DEBUG_ENABLED_EQUIPMENT
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_EQUIPMENT
    #define DEBUG_SETTINGS DEBUG_SETTINGS_EQUIPMENT
#endif


#include "\z\jmfsb\addons\main\script_mod.hpp"
#include "\z\jmfsb\addons\main\script_macros.hpp"

#define SERVER_OWNER 2
// The Vector designators, their reach (the raycast's 5 km) and the slack the
// server allows on it when it checks a 3D marker request (review R1).
#define VECTOR_DESIGNATORS [QGVAR(Vector_Designator), QGVAR(Vector_Designator_NVG)]
#define VECTOR_RANGE 5000
#define VECTOR_RANGE_SLACK 50

