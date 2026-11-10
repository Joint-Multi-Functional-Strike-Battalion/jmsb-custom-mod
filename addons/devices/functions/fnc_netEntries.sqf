#include "script_component.hpp"
/*
 * Author: YonV
 * Every voice net the player is on, as the net rows draw them (docs/DESIGN_VOICE.md,
 * "Nets on the devices") - before they are put on the net buttons
 * (FUNC(netButtons)) and numbered for the page shown (FUNC(overlayNets)):
 *
 * - ONLY NETS THE PLAYER IS ON: the voice API's own list
 *   (jmfsb_voice_fnc_netState), in its order. VEH appears inside a vehicle
 *   and CALL while a call is live, because that is when the API lists them.
 *   Direct voice is not a net and has no cell.
 * - A NET HE CANNOT REACH IS NOT HIDDEN: it is answered with reachable false,
 *   and the rows draw it with a red outline.
 * - THE EAR TAG (L / B / R) rides on each cell. VON cannot pan voice, so the
 *   ear pans the net's beeps and static.
 * - A RINGING CALL with no call net yet gets a RING entry of its own (kind
 *   NET_KIND_RING), last, so the row shows the ring the notification line
 *   names.
 * - RECEIVE ONLY: a radio net while any set of his is at EMCON 3 (SILENT),
 *   as jmfsb_ew's slice says (FUNC(emconLevel)) - voice closes all his radio
 *   nets then (jmfsb_voice_fnc_blockLevel). A radio net is one an RF net
 *   carries (jmfsb_voice_fnc_rfNet): not VEH, not DIRECT. Never without EW.
 * - TRANSMITTING is the player himself among the net's talkers - the voice
 *   API lists him there while he talks (user, 2026-10-21: "need feedback
 *   that you're talking on a net").
 *
 * NEVER A FREQUENCY. A net is a name.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Entries of [0, name, active, net id, reachable, ear, muted, kind, quality
 * 0-1, transmitting, receive only] - the number and the label are
 * FUNC(overlayNets)' to set; [] without the voice addon <ARRAY>
 *
 * Example:
 * private _entries = [] call jmfsb_devices_fnc_netEntries
 *
 * Public: No
 */

if (isNil QEFUNC(voice,netState)) exitWith {[]};

private _out = [];
private _silent = ([] call FUNC(emconLevel)) >= EMCON_RECEIVE_ONLY;
private _me = call CBA_fnc_currentUnit;
{
    _x params [["_netId", "", [""]], ["_name", "", [""]], ["_kind", "", [""]], ["_active", false, [false]], ["_muted", false, [false]], ["_ear", "B", [""]], ["_reach", false, [false]], ["_talkers", [], [[]]], ["_quality", -1, [0]]];
    if (_kind isEqualTo VOICE_KIND_DIRECT) then {continue};
    private _label = toUpper _name;
    if (count _label > NET_NAME_MAX) then {_label = _label select [0, NET_NAME_MAX]};
    if (_quality < 0) then {_quality = parseNumber _reach};
    private _tx = (_talkers findIf {(_x param [0, objNull]) isEqualTo _me}) >= 0;
    private _receiveOnly = _silent && {([_netId] call EFUNC(voice,rfNet)) isNotEqualTo ""};
    _out pushBack [0, _label, _active, _netId, _reach, _ear, _muted, _kind, _quality, _tx, _receiveOnly];
} forEach ([] call EFUNC(voice,netState));

if (!isNil QEFUNC(voice,calls)) then {
    private _ringing = (([] call EFUNC(voice,calls)) findIf {(_x param [1, ""]) isEqualTo CALL_RINGING}) >= 0;
    private _callNet = (_out findIf {(_x select 7) isEqualTo VOICE_KIND_CALL}) >= 0;
    if (_ringing && !_callNet) then {
        _out pushBack [0, "RING", false, "", true, "", false, NET_KIND_RING, 1, false, false];
    };
};

_out
