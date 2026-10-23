#define COMPONENT players
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written
// against, plus the notification colours and the logistics shorthand. Included
// AFTER jmfsb's macros so the #undef in there lands on the right definitions.
#include "\z\jmfsb\addons\diag\roomba_macros.hpp"

// The PAC net plan's kinds (jmfsb_pac_fnc_netPlan / netPlanSquad): a squad's
// short range (TEAM) net and its long range net. TFAR tuning reads them.
#define PLAN_KIND_SR "sr"
#define PLAN_KIND_LR "lr"
#define PLAN_NO_SLOT -1
