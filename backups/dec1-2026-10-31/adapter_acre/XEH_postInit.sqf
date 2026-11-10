#include "script_component.hpp"

// CLIENT: this player's ACRE radios as RF nodes and as the voice API's nets
// (fnc_poll), and who talks on a radio, from ACRE's own speaking events:
// acre_startedSpeaking / acre_stoppedSpeaking for him (local), and
// acre_remoteStartedSpeaking / acre_remoteStoppedSpeaking for the others.
if (hasInterface) then {
    ["CBA_settingsInitialized", {
        [{_this call FUNC(poll)}, POLL_S] call CBA_fnc_addPerFrameHandler;
    }] call CBA_fnc_addEventHandler;

    ["acre_startedSpeaking", {
        params ["", ["_onRadio", false, [false]], ["_radioId", "", [""]]];
        GVAR(txNet) = ["", ([_radioId] call FUNC(radioNet)) select 0] select (_onRadio && _radioId isNotEqualTo "");
    }] call CBA_fnc_addEventHandler;
    ["acre_stoppedSpeaking", {GVAR(txNet) = ""}] call CBA_fnc_addEventHandler;

    ["acre_remoteStartedSpeaking", {
        params [["_unit", objNull, [objNull]], ["_type", 0, [0]], ["_radioId", "", [""]]];
        [_unit, _type isEqualTo ACRE_SPEAKING_RADIO, _radioId] call FUNC(heard);
    }] call CBA_fnc_addEventHandler;
    ["acre_remoteStoppedSpeaking", {
        params [["_unit", objNull, [objNull]]];
        [_unit, false] call FUNC(heard);
    }] call CBA_fnc_addEventHandler;
};
