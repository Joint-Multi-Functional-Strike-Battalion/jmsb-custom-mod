#include "script_component.hpp"
/*
 * Author: JMSB
 * The VON channel a voice net rides on, in words (DESIGN_VOICE.md, "Channels"):
 * Group, Vehicle, Custom 1 .. Custom 10. Read off the net's voiceChannel in
 * jmfsb_voice_fnc_nets; a net the list does not carry reads "--".
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: The player's nets, as jmfsb_voice_fnc_nets answers <ARRAY>
 *
 * Return Value:
 * Channel name <STRING>
 *
 * Example:
 * private _von = ["C2", _nets] call jmfsb_tacpad_apps_fnc_radioVon
 *
 * Public: No
 */

params [["_netId", "", [""]], ["_nets", [], [[]]]];

private _i = _nets findIf {(_x param [0, ""]) isEqualTo _netId};
if (_i < 0) exitWith {"--"};

private _channel = (_nets select _i) param [3, -1];
if !(_channel isEqualType 0) exitWith {"--"};

private _named = VON_CHANNEL_NAMES findIf {(_x select 0) isEqualTo _channel};
if (_named >= 0) exitWith {(VON_CHANNEL_NAMES select _named) select 1};
if (_channel >= VON_CUSTOM_BASE) exitWith {format ["Custom %1", _channel - VON_CUSTOM_BASE + 1]};

"--"
