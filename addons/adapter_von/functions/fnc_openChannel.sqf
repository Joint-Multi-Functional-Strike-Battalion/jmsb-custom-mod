#include "script_component.hpp"
/*
 * Author: YonV
 * The channel the player's mic should sit on when no talk key is held.
 *
 * Push to talk (the default): the active net, as it always was - his Push To
 * Talk key transmits on it and Arma's own Talk on Direct key is his local voice.
 *
 * Voice activation (GVAR(vad), the player's own setting: he has set Arma's VON
 * to voice activation under Options > Audio): the engine transmits on the
 * current channel whenever he speaks, so the current channel IS his open mic.
 * A live call takes it while it lasts (GVAR(vaCalls)), else the OPEN CHANNEL
 * toggle (FUNC(openToggle)) says NET or LOCAL, and LOCAL is Direct - the
 * people round him, which is what an open mic should reach by default.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * VON channel id, CH_NONE when there is nothing to sit on <NUMBER>
 *
 * Example:
 * private _ch = [] call jmfsb_adapter_von_fnc_openChannel
 *
 * Public: No
 */

if (!GVAR(vad)) exitWith {GVAR(activeCh)};

private _call = CH_NONE;
if (GVAR(vaCalls)) then {_call = [] call FUNC(liveCallChannel)};
if (_call > CH_NONE) exitWith {_call};

if (GVAR(openNet)) exitWith {GVAR(activeCh)};

CH_DIRECT
