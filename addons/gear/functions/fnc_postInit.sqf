#include "script_component.hpp"
/*
 * Author: BaerMitUmlaut, CPL.Brostrom.A
 * This function runs on postInit unsceduled via made sure by postInitProxy
 *
 * Arguments:
 * none
 *
 * Return Value:
 * nothing
 *
 * Example:
 * call jmfsb_gear_fnc_postInit
 *
 */
// Server programs the ACRE preset and raises the flag that gates vehicle-rack setup
// (fn_vehicle_addRadio waits on GVAR(Radio)). Each client programs its own local preset
// in fn_init_playerpost - ACRE presets are per-machine.
if (isServer) then {
    GVAR(Radio) = false;
    call EFUNC(gear,setupRadios);
    GVAR(Radio) = true;
};


if (hasInterface) then {
    ["ace_arsenal_displayClosed", {
        [player, 'BIS'] call EFUNC(players,setRank);
        call (missionNamespace getVariable ["jmfsb_w28fixes_fnc_player_set_name", {}]);
        player linkItem "ItemCompass";
        // THE GPS SLOT IS KEPT when it holds a JMSB device (jmfsb_devices: the
        // phone and side devices, which also fly drones now that the vanilla
        // UAV terminal is out of the arsenal) or a UAV terminal a loadout still
        // carries; the Android goes in the pack then. Otherwise it is linked.
        private _gps = player getSlotItemName 612;
        private _keep = _gps isKindOf ["UavTerminal_base", configFile >> "CfgWeapons"]
            || {!isNil QEFUNC(devices,overlayDevice) && {([] call EFUNC(devices,overlayDevice)) isNotEqualTo ""}};
        if (_keep) then {
            if !([player, "ItemAndroidMisc"] call ace_common_fnc_hasItem) then {player addItem "ItemAndroidMisc"};
        } else {
            if !([player, "ItemAndroid"] call ace_common_fnc_hasItem) then {player linkItem "ItemAndroid"};
        };
        player call EFUNC(gear,saveLoadout);
    }] call CBA_fnc_addEventHandler;
};
