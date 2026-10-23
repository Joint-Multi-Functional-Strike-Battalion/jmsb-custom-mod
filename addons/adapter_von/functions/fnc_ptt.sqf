#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "ptt", client, every frame: is the local player keying, and on
 * which net. Every PTT input is read with inputAction: a per-channel key
 * (All, Side, Command, Group, Vehicle, Direct) sends on its own channel,
 * Push To Talk and the VON toggle on the current one; the channel's net is
 * the one the key transmits on (Direct = DIRECT). With no key held, his own
 * getPlayerChannel is the fallback (an input inputAction does not see, the
 * toggle left open).
 *
 * Arguments:
 * 0: Use the getPlayerChannel fallback <BOOL> (default: true)
 *
 * Return Value:
 * [down <BOOL>, net id ("" when the channel is none of ours) <STRING>, VON channel <NUMBER>] <ARRAY>
 *
 * Example:
 * [] call jmfsb_adapter_von_fnc_ptt
 *
 * Public: No
 */

params [["_fallback", true, [true]]];

if (isNull player) exitWith {[false, "", CH_NONE]};

private _i = PTT_ACTIONS findIf {(inputAction (_x select 0)) > 0};
private _ch = CH_NONE;
if (_i >= 0) then {
    _ch = (PTT_ACTIONS select _i) select 1;
    if (_ch isEqualTo CH_CURRENT) then {_ch = currentChannel};
} else {
    if (_fallback) then {_ch = getPlayerChannel player};
};
if (_ch <= CH_NONE) exitWith {[false, "", CH_NONE]};
[true, [player, _ch] call FUNC(netOf), _ch]
