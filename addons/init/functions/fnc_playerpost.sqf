#include "script_component.hpp"
/*
 * Author: YonV
 * This function provides post init player set up.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call jmfsb_init_fnc_playerpost
 *
 * Public: No


 */// Change inventory content of supply crates on mission start.
call EFUNC(init,vehicle);

// staging
call EFUNC(init,staging);

// messages and diary records
//
// THE WAIT LIVES HERE, NOT IN THE TWO FUNCTIONS. Both need a real `player`,
// and this runs from XEH postInit - an UNSCHEDULED context, where waitUntil
// does not wait, it throws. Each function used to open with its own
// waitUntil; each threw "Suspending not allowed in this context", each had
// its wait abandoned, and each then ran anyway against a null player. The
// proof was in every RPT, one line below the error:
//
//     [jmfsb] (initDiary) INFO: Applying Diary Records to <NULL-object>
//
// CBA's waitUntilAndExecute does the same wait from a per-frame handler,
// which needs no suspension. `profileName` is folded in because FUNC(diary) wanted it
// too. A dedicated server never has a player, so hasInterface skips both
// outright rather than parking a handler that can never fire.
if (hasInterface) then {
    [
        {!isNull player && {player == player} && {profileName != ""}},
        {
            call EFUNC(init,message);

            if (EGVAR(Settings,showDiaryRecords)) then {
                call EFUNC(init,diary);
            };
        },
        []
    ] call CBA_fnc_waitUntilAndExecute;
};

// No radio presets or tuning at login: game voice takes a squad's nets from
// the PAC net plan (jmfsb_voice). The ACRE / TFAR tuning went with DEC1.

