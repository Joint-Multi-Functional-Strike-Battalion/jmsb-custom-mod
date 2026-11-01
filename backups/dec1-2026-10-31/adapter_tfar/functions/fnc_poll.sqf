#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every POLL_S: this player's TFAR sets as RF nodes. A set's node is
 * registered (rf_register) when it appears or its object, profile or fill
 * changes, its state (on, active and monitor net, tx) is sent (rf_setState)
 * when it changes, and it is unregistered when the set is gone. Nothing is
 * sent when nothing changed. tx is whether this set's tangent is down
 * (fnc_tangent, which also calls this at once).
 *
 * NETS OVER FREQUENCIES: a set's channels are read back as nets
 * (fnc_radioNets: by frequency, else by the plan's channel number). Its RF
 * fill is the nets its channels carry, plus DATA; its active and monitor nets
 * are the nets on its current and additional channel, "" for a channel that
 * carries none. When any set's state changed, the voice levers are re-applied
 * (fnc_applyVoice): a channel switch changes which nets he listens to.
 *
 * NEW SETS GET THE PLAN'S FILL (setting "Fill new sets from the plan"): the
 * first time this client sees a handheld or a backpack set - spawn, respawn,
 * a set picked up - and none of its channels carries a net by frequency, it
 * is programmed with the plan's fill (fnc_program). A set already on the
 * plan's frequencies, a captured set on someone else's, and a vehicle's rack
 * (the crew's to load) are left as they are.
 *
 * Last, the voice API's view of his sets is rebuilt (fnc_voiceView).
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], -1] call jmfsb_adapter_tfar_fnc_poll
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

if (isNull player) exitWith {};

private _plan = [] call FUNC(planNets);
private _uid = getPlayerUID player;
private _seen = [];
private _changed = false;
private _sets = [] call FUNC(radios);

{
    _x params ["_kind", "_object", "_profile", "_channel", "_monitor", "_on", "_radio"];
    private _id = format [NODE_ID_FORMAT, _uid, _kind];
    _seen pushBack _id;

    private _netKind = [NODE_LR, NODE_SR] select (_kind isEqualTo NODE_SR);
    private _read = [_radio, _netKind, _plan] call FUNC(radioNets);

    private _setKey = str _radio;
    if (GVAR(fillOnIssue) && _kind isNotEqualTo NODE_VEH && _plan isNotEqualTo [] && !(_setKey in GVAR(filled))) then {
        GVAR(filled) set [_setKey, true];
        if ((_read select 1) == 0) then {
            [_radio, _netKind, [], _plan] call FUNC(program);
            _read = [_radio, _netKind, _plan] call FUNC(radioNets);
            INFO_2("new %1 set loaded with the plan's fill: %2",_kind,_read select 0);
        };
    };

    private _channelNets = _read select 0;
    private _nets = _channelNets select {_x isNotEqualTo ""};
    _nets = _nets arrayIntersect _nets;
    _nets pushBack NET_DATA;
    private _active = _channelNets param [_channel, ""];
    private _monitorNet = if (_monitor > NO_CHANNEL) then {_channelNets param [_monitor, ""]} else {""};
    GVAR(channels) set [_kind, _channel];

    private _reg = [_object, _profile, _nets, _id, OWNER_TAG, player];
    private _state = [["on", _on], ["activeNet", _active], ["monitorNet", _monitorNet], ["tx", GVAR(txKind) isEqualTo _kind]];
    (GVAR(sent) getOrDefault [_id, [[], []]]) params ["_regWas", "_stateWas"];

    if (_reg isNotEqualTo _regWas) then {
        _reg call EFUNC(rf,register);
        _stateWas = [];
    };
    if (_state isNotEqualTo _stateWas) then {
        [_id, _state] call EFUNC(rf,setState);
        _changed = true;
    };
    GVAR(sent) set [_id, [_reg, _state]];
} forEach _sets;

{
    [_x] call EFUNC(rf,unregister);
    GVAR(sent) deleteAt _x;
    _changed = true;
} forEach ((keys GVAR(sent)) - _seen);

if (_changed) then {[] call FUNC(applyVoice)};
[_sets] call FUNC(voiceView);
