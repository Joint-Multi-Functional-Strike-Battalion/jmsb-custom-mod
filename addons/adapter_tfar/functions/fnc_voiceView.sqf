#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, end of every fnc_poll: this player's TFAR sets as the voice API sees
 * them (jmfsb_voice reads these through its hooks, addons/voice/README.md):
 *
 *   GVAR(nets)    [[net, name, kind, -1], ...] - the nets his sets HEAR: each
 *                 set's active and additional channel, the first set to carry
 *                 a net keeps it (handheld, then backpack, then rack);
 *   GVAR(rows)    [[net, name, kind, active, muted, ear, reachable], ...] -
 *                 muted = the set's volume is 0, ear = TFAR's stereo setting
 *                 of that channel, reachable = the set is on and RF does not
 *                 say "no link" on the net (RF's "unknown" counts as reachable);
 *   GVAR(current) the net the voice API calls active: the active channel's
 *                 net of the set last picked (GVAR(activeKind), the handheld
 *                 first), else of the first set;
 *   GVAR(slots)   net -> [set kind, TFAR radio, additional channel].
 *
 * A net's kind is the plan's (team, c2, a2g); a net the plan does not name is
 * team on a handheld and c2 on a long range set. Its name is its id. Nothing
 * here is a frequency.
 *
 * Arguments:
 * 0: The sets, as fnc_radios read them this poll <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[] call jmfsb_adapter_tfar_fnc_radios] call jmfsb_adapter_tfar_fnc_voiceView
 *
 * Public: No
 */

params [["_sets", [], [[]]]];

private _plan = [] call FUNC(planNets);
private _uid = getPlayerUID player;
private _nets = [];
private _rows = [];
private _slots = createHashMap;
private _actives = createHashMap;

{
    _x params ["_kind", "", "", "", "", "_on", "_radio"];
    private _id = format [NODE_ID_FORMAT, _uid, _kind];
    private _state = createHashMapFromArray ((GVAR(sent) getOrDefault [_id, [[], []]]) select 1);
    private _isSr = _kind isEqualTo NODE_SR;
    private _volume = _radio call ([TFAR_fnc_getLrVolume, TFAR_fnc_getSwVolume] select _isSr);
    private _muted = _volume isEqualTo VOLUME_MUTED;
    _actives set [_kind, _state getOrDefault ["activeNet", ""]];
    {
        _x params ["_net", "_additional"];
        if (_net isEqualTo "" || {_net in _slots}) then {continue};
        _slots set [_net, [_kind, _radio, _additional]];
        private _at = _plan findIf {(_x select 0) isEqualTo _net};
        private _netKind = if (_at >= 0) then {(_plan select _at) select 4} else {[KIND_C2, KIND_TEAM] select _isSr};
        private _stereo = _radio call ([
            [TFAR_fnc_getLrStereo, TFAR_fnc_getAdditionalLrStereo],
            [TFAR_fnc_getSwStereo, TFAR_fnc_getAdditionalSwStereo]
        ] select _isSr select _additional);
        private _quality = [_id, _net] call EFUNC(rf,quality);
        _nets pushBack [_net, _net, _netKind, NO_CHANNEL];
        _rows pushBack [
            _net, _net, _netKind, false, _muted,
            TFAR_STEREO_EARS param [_stereo, EAR_BOTH],
            _on isEqualTo true && _quality != 0
        ];
    } forEach [
        [_state getOrDefault ["activeNet", ""], false],
        [_state getOrDefault ["monitorNet", ""], true]
    ];
} forEach _sets;

// the active net: the picked set's (a long range pick takes the rack when
// there is no backpack), else the first set's
private _current = "";
private _order = [GVAR(activeKind)];
if (GVAR(activeKind) isEqualTo NODE_LR) then {_order pushBack NODE_VEH};
_order append [NODE_SR, NODE_LR, NODE_VEH];
{
    private _net = _actives getOrDefault [_x, ""];
    if (_net isNotEqualTo "") exitWith {_current = _net};
} forEach _order;

{
    _x set [3, (_x select 0) isEqualTo _current];
} forEach _rows;

GVAR(nets) = _nets;
GVAR(rows) = _rows;
GVAR(current) = _current;
GVAR(slots) = _slots;
