#include "script_component.hpp"
/*
 * Author: JMSB
 * The voice nets for the device net rows - the walking view's bottom row and
 * the tablet's (docs/DESIGN_VOICE.md, "Nets on the devices"):
 *
 * - ONLY NETS THE PLAYER IS ON: the voice API's own list
 *   (jmfsb_voice_fnc_netState). VEH appears inside a vehicle and CALL while a
 *   call is live, because that is when the API lists them. Direct voice is
 *   not a net and has no cell.
 * - A NET HE CANNOT REACH IS NOT HIDDEN: it is answered with reachable false,
 *   and the rows draw it with a red outline.
 * - THE EAR TAG (L / B / R) rides on each cell. VON cannot pan voice, so the
 *   ear pans the net's beeps and static.
 * - A RINGING CALL with no call net yet gets a RING cell of its own, so the
 *   row shows the ring the notification line names.
 *
 * NUMBERED. A cell reads "<N> <NAME>": N is its place in the row and the
 * SELECT NET N key (FUNC(netSelect); numpad 1-4 by default).
 *
 * NEVER A FREQUENCY. A net is a name.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Entries of [number (1-based), label, active, net id, reachable, ear, muted,
 * kind, quality 0-1, transmitting] - kind "ring" for the ringing cell; [] without
 * the voice addon <ARRAY>
 *
 * TRANSMITTING is the player himself among the net's talkers - the voice API
 * lists him there while he talks (user, 2026-10-21: "need feedback that
 * you're talking on a net").
 *
 * Example:
 * private _nets = [] call jmfsb_devices_fnc_overlayNets
 *
 * Public: Yes
 */

if (isNil QEFUNC(voice,netState)) exitWith {[]};

private _out = [];
{
    _x params [["_netId", "", [""]], ["_name", "", [""]], ["_kind", "", [""]], ["_active", false, [false]], ["_muted", false, [false]], ["_ear", "B", [""]], ["_reach", false, [false]], ["_talkers", [], [[]]], ["_quality", -1, [0]]];
    if (_kind isEqualTo VOICE_KIND_DIRECT) then {continue};
    private _name = toUpper _name;
    if (count _name > NET_NAME_MAX) then {_name = _name select [0, NET_NAME_MAX]};
    if (_quality < 0) then {_quality = parseNumber _reach};
    private _number = count _out + 1;
    private _me = call CBA_fnc_currentUnit;
    private _tx = (_talkers findIf {(_x param [0, objNull]) isEqualTo _me}) >= 0;
    _out pushBack [_number, format ["%1 %2", _number, _name], _active, _netId, _reach, _ear, _muted, _kind, _quality, _tx];
} forEach ([] call EFUNC(voice,netState));

if (!isNil QEFUNC(voice,calls)) then {
    private _ringing = (([] call EFUNC(voice,calls)) findIf {(_x param [1, ""]) isEqualTo CALL_RINGING}) >= 0;
    private _callNet = (_out findIf {(_x select 7) isEqualTo VOICE_KIND_CALL}) >= 0;
    if (_ringing && !_callNet) then {
        _out pushBack [count _out + 1, "RING", false, "", true, "", false, NET_KIND_RING, 1, false];
    };
};

_out
