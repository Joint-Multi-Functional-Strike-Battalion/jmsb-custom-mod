#include "script_component.hpp"
/*
 * Author: JMSB
 * onLoad of the game's talking popup (RscDisplayVoiceChat, RscDisplayVoiceChat.hpp):
 * under game voice the vanilla microphone is hidden and our chip says what the
 * player is talking on - "TX GHOST 1", "TX GLOBAL" - kept current every
 * VOICECHAT_TICK_S while the popup is up (he can change channel mid-key). Under
 * TFAR / ACRE voice has stood down and the popup is left as the game made it,
 * our chip hidden.
 *
 * Arguments:
 * 0: The popup <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_adapter_von_fnc_voiceChatLoad
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

private _chip = _display displayCtrl IDC_VOICECHAT_TX;
if (!EGVAR(voice,active)) exitWith {_chip ctrlShow false};

{
    if (_x isNotEqualTo _chip) then {_x ctrlShow false};
} forEach (allControls _display);

[{
    params ["_args", "_handle"];
    _args params ["_display", "_chip"];
    if (isNull _display) exitWith {[_handle] call CBA_fnc_removePerFrameHandler};

    // The net the key sends on (voice's own), else the net the current channel
    // is (FUNC(netOf): Group is his TEAM net - "TX GHOST 1", not "TX GROUP";
    // user, 2026-10-21), else the engine channel by name - Global, Direct and
    // the rest carry no net of ours.
    private _net = EGVAR(voice,keyNet);
    if (_net isEqualTo "") then {_net = [player, currentChannel] call FUNC(netOf)};
    private _name = if (_net isNotEqualTo "") then {[_net] call EFUNC(voice,netName)} else {
        VOICECHAT_CHANNEL_NAMES param [currentChannel, ""]
    };
    _chip ctrlSetStructuredText parseText format [
        "<t color='%1'> %2</t> TX  %3", VOICECHAT_DOT_HEX, VOICECHAT_DOT, toUpper _name
    ];
}, VOICECHAT_TICK_S, [_display, _chip]] call CBA_fnc_addPerFrameHandler;
