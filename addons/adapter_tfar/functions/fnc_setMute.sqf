#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "setMute", client: mutes or unmutes the set that hears a net -
 * TFAR has one volume per set, so both of its nets go quiet. Muting keeps the
 * set's volume and puts it at 0; unmuting puts the kept volume back (TFAR's
 * default when none was kept).
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Muted <BOOL>
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * ["A2G", true] call jmfsb_adapter_tfar_fnc_setMute
 *
 * Public: No
 */

params [["_net", "", [""]], ["_muted", true, [true]]];

private _slot = GVAR(slots) getOrDefault [_net, []];
if (_slot isEqualTo []) exitWith {false};
_slot params ["_kind", "_radio"];
private _isSr = _kind isEqualTo NODE_SR;
private _key = str _radio;
private _volume = _radio call ([TFAR_fnc_getLrVolume, TFAR_fnc_getSwVolume] select _isSr);

if (_muted) then {
    if (!(_volume isEqualType 0)) then {_volume = VOLUME_MUTED};
    if (_volume > VOLUME_MUTED) then {GVAR(volumes) set [_key, _volume]};
    [_radio, VOLUME_MUTED] call ([TFAR_fnc_setLrVolume, TFAR_fnc_setSwVolume] select _isSr);
} else {
    [_radio, GVAR(volumes) getOrDefault [_key, VOLUME_DEFAULT]] call ([TFAR_fnc_setLrVolume, TFAR_fnc_setSwVolume] select _isSr);
    GVAR(volumes) deleteAt _key;
};
[[], -1] call FUNC(poll);
true
