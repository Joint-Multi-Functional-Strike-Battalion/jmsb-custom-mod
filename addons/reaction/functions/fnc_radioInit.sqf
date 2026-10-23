#include "script_component.hpp"
/*
 * Author: JMSB
 * Arms this client's transmission watch.
 *
 * Game voice (jmfsb_voice) raises jmfsb_voice_talk [unit, net, on]; only the
 * player's own key-up on a net that leaves the squad is reported - the TEAM
 * net, the vehicle intercom and direct speech never reach the filter, so the
 * squad net is always safe. ACRE has no such event, so it is polled for the
 * rising edge of isBroadcasting.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

if (!hasInterface) exitWith {};
if (!isNil QGVAR(radioReady)) exitWith {};
GVAR(radioReady) = true;

// Game voice: registered whether or not jmfsb_voice is loaded - a CBA event
// nobody raises costs nothing.
[QEGVAR(voice,talk), {
    params [["_unit", objNull, [objNull]], ["_net", "", [""]], ["_on", false, [false]]];
    if (!_on || _unit isNotEqualTo player || isNil QEFUNC(voice,nets)) exitWith {};
    if ((missionNamespace getVariable [QEGVAR(voice,system), ""]) isEqualTo REACT_VOICE_SYSTEM_ACRE) exitWith {};
    private _nets = [player] call EFUNC(voice,nets);
    private _i = _nets findIf {(_x param [0, ""]) isEqualTo _net};
    if (_i < 0) exitWith {};
    if (((_nets select _i) param [2, ""]) in REACT_VOICE_SAFE_KINDS) exitWith {};
    [""] call FUNC(onTransmit);
}] call CBA_fnc_addEventHandler;

if (isClass (configFile >> "CfgPatches" >> "acre_main")
    && {!isNil "acre_api_fnc_isBroadcasting"}) then {
    GVAR(wasTx) = false;
    [{
        private _tx = [] call acre_api_fnc_isBroadcasting;
        if (_tx && {!GVAR(wasTx)}) then {
            private _radio = "";
            if (!isNil "acre_api_fnc_getCurrentRadio") then {
                _radio = [] call acre_api_fnc_getCurrentRadio;
            };
            [_radio] call FUNC(onTransmit);
        };
        GVAR(wasTx) = _tx;
    }, 1, []] call CBA_fnc_addPerFrameHandler;
};
