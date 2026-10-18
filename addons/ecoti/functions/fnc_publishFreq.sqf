#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the local player's current radio frequency where everyone's ECOTI net
 * card can read it (FUNC(targetCard)). The TAC//PAD publishes his channel and
 * its name but not the frequency, and no radio mod answers for another
 * player's set - so each man says his own.
 *
 * ONLY WHEN IT CHANGES, as the TAC//PAD's channel does: a public variable is a
 * network message, and an unchanged one every few seconds is noise.
 *
 * ACRE: the frequency of the current radio's channel in its preset. TFAR: the
 * active short-wave's frequency. Neither loaded, or nothing in hand: "".
 *
 * Arguments (CBA per-frame handler):
 * 0: Arguments <ARRAY> - unused
 * 1: Handle <NUMBER> - unused
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], 0] call jmfsb_ecoti_fnc_publishFreq
 *
 * Public: No
 */

if (isNull player) exitWith {};

private _freq = call {
    if (!isNil "acre_api_fnc_getCurrentRadio") exitWith {
        private _radio = [] call acre_api_fnc_getCurrentRadio;
        if (_radio isEqualTo "") exitWith {""};
        private _base = [_radio] call acre_api_fnc_getBaseRadio;
        private _mhz = [_base, [_base] call acre_api_fnc_getPreset, [_radio] call acre_api_fnc_getRadioChannel, "frequencyRX"] call acre_api_fnc_getPresetChannelField;
        if !(_mhz isEqualType 0) exitWith {""};
        format ["%1 MHz", _mhz toFixed FREQ_DECIMALS]
    };
    if (!isNil "TFAR_fnc_activeSwRadio") exitWith {
        private _radio = call TFAR_fnc_activeSwRadio;
        if (isNil "_radio") then {_radio = ""};
        if (_radio isEqualTo "") exitWith {""};
        format ["%1 MHz", [_radio] call TFAR_fnc_getSwFrequency]
    };
    ""
};

if (_freq isEqualTo (player getVariable [QGVAR(freq), ""])) exitWith {};
player setVariable [QGVAR(freq), _freq, true];
