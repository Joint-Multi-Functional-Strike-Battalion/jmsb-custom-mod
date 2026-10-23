#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A
 * This function sets a defined radio to be the active radio after radio init.
 *
 * Arguments:
 * 0: Radio <STRING> (Default; MyDefaultValue)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["ACRE_PRC343"] call ymf_fnc_setActiveRadio
 *
 * Public: No
 */

params [["_radio", 'ACRE_PRC148', ['ACRE_PRC148']]];

// ACRE or TFAR. Game voice (jmfsb_voice) has nets, not radios to put in hand.
if (!EGVAR(Patches,usesACRE) && !EGVAR(Patches,usesTFAR)) exitWith {};
if (!EGVAR(Settings,enableRadios)) exitWith {};
if (!EGVAR(init,isPlayer)) exitWith {};

// ACRE
if (EGVAR(patches,usesACRE)) exitWith {
    [{
        _this params ["_radio"];

        private _radioId = [_radio] call acre_api_fnc_getRadioByType;
        [_radioId] call acre_api_fnc_setCurrentRadio;
        
        INFO_2("RadioSetActive","%1 radio %2 is current radio",player,call acre_api_fnc_getCurrentRadio)
    }, [_radio], 1] call CBA_fnc_waitAndExecute;
};

// TFAR - the handheld of that arsenal class in hand (jmfsb_adapter_tfar)
if (isNil QEFUNC(adapter_tfar,activeRadio)) exitWith {};
[_radio] call EFUNC(adapter_tfar,activeRadio);

