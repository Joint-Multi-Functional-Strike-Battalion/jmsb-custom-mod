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
// which needs no suspension - the pattern this file already uses for ACRE
// and TFAR below. `profileName` is folded in because FUNC(diary) wanted it
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

onPlayerConnected { 
    [QEGVAR(log,player), [getPlayerUID player, player]] call CBA_fnc_serverEvent;
};

//radio - clients program their own local ACRE preset (the server already did in fn_gear_postInit;
//ACRE presets are per-machine, so each client still needs its own copy).
if (!isServer) then { call EFUNC(gear,setupRadios); };

//login default: once ACRE is up, tune radios to the pre-join defaults (343 -> COMMON ch241,
//152/148 -> DET, 117F -> DET) and make the SR handheld the active radio. This holds until the
//player joins a dynamic group, at which point fn_setupPlayer re-tunes to that group's nets.
if (EGVAR(patches,usesACRE) && GVAR(isPlayer)) then {
    [{[] call acre_api_fnc_isInitialized}, {
        [player] call EFUNC(players,setRadioChannel);
        [jmfsbFR_radio_acreActiveRadio] call EFUNC(players,setActiveRadio);
    }, []] call CBA_fnc_waitUntilAndExecute;
};

//same login default under TFAR - wait until the SW handheld exists, then tune to the net plan
//(jmfsb_adapter_tfar_fnc_tune through setRadioChannel) and put the plan's handheld in hand
if (EGVAR(patches,usesTFAR) && GVAR(isPlayer)) then {
    [{ private _r = call TFAR_fnc_activeSwRadio; !isNil "_r" && {_r isEqualType "" && _r isNotEqualTo ""} }, {
        [player] call EFUNC(players,setRadioChannel);
        [missionNamespace getVariable ["jmfsbFR_radio_tfarActiveRadio", ""]] call EFUNC(players,setActiveRadio);
    }, []] call CBA_fnc_waitUntilAndExecute;
};

