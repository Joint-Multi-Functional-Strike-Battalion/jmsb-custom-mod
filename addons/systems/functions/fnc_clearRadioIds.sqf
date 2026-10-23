#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A
 * This function return a funtion icon path or path provided.
 *
 * Arguments:
 * nothing
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [player] call ymf_fnc_clearRadioIds
 *
 */

// ACRE or TFAR: game voice has no radio IDs to clear and nothing to re-tune.
if (!EGVAR(Patches,usesACRE) && !EGVAR(Patches,usesTFAR)) exitWith {};
if (!EGVAR(Settings,enableRadios)) exitWith {};
if (!EGVAR(init,isPlayer)) exitWith {};

// ACRE
if (EGVAR(patches,usesACRE)) exitWith {
    private _playerRadios = [] call acre_api_fnc_getCurrentRadioList;

    {
        private _base = [_x] call acre_api_fnc_getBaseRadio;
        player removeItem _x;
        player addItem _base;
    } forEach _playerRadios;

    [{
        [player] call EFUNC(players,setRadioChannel);
        [jmfsbFR_radio_acreActiveRadio] call EFUNC(players,setActiveRadio);
    }] call CBA_fnc_execNextFrame;

    ["Radios", "Your radios have been reset.", NOTE_GOOD] call JMFSBFUNC(notify,notify);

    SHOW_CHAT_SERVER_INFO_1("ClearRadioID","%1: Your radios have been reset",name player)
};

// TFAR - re-tune from the net plan and put the plan's handheld in hand (TFAR
// has no stuck radio-ID issue to clear)
[{
    [player] call EFUNC(players,setRadioChannel);
    [missionNamespace getVariable ["jmfsbFR_radio_tfarActiveRadio", ""]] call EFUNC(players,setActiveRadio);
}] call CBA_fnc_execNextFrame;

["Radios", "Your radios have been reset.", NOTE_GOOD] call JMFSBFUNC(notify,notify);

SHOW_CHAT_SERVER_INFO_1("ClearRadioID","%1: Your radios have been reset",name player)
