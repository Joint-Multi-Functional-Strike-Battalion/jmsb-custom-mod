#include "script_component.hpp"
/*
 * Author: YonV
 * The VON channel of the call the player is in right now, live and accepted -
 * not one still ringing him, and not one he is dialling.
 *
 * Read off the voice core's published call table, whose rows the core lays out
 * as [id, slot, from, members, ringing, priority, startedAt, live, ...]
 * (jmfsb_voice_fnc_ringTick reads the same columns); a call's net is named
 * from its slot the way the core names it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Channel id, CH_NONE when he is in no live call <NUMBER>
 *
 * Example:
 * private _ch = [] call jmfsb_adapter_von_fnc_liveCallChannel
 *
 * Public: No
 */

if (isNull player) exitWith {CH_NONE};

private _table = missionNamespace getVariable [QEGVAR(voice,callTable), []];
private _ch = CH_NONE;
{
    _x params ["", ["_slot", 0, [0]], "", ["_members", [], [[]]], "", "", "", ["_live", false, [false]]];
    if (_live && {player in _members}) exitWith {
        _ch = [format [CALL_NET_FORMAT, _slot]] call FUNC(channel);
    };
} forEach _table;

_ch
