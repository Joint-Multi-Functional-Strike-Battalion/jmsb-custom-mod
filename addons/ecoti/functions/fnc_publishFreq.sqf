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
 * ACRE: the frequency of the current radio's channel in its preset. Game voice
 * (jmfsb_voice) has nets, not frequencies: the active net instead ("NET C2").
 * Neither loaded, or nothing in hand / no active net: "".
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
    if (!isNil QEFUNC(voice,activeNet)) exitWith {
        private _net = [] call EFUNC(voice,activeNet);
        if (!(_net isEqualType "") || _net isEqualTo "") exitWith {""};
        format ["NET %1", _net]
    };
    ""
};

if (_freq isEqualTo (player getVariable [QGVAR(freq), ""])) exitWith {};
player setVariable [QGVAR(freq), _freq, true];
