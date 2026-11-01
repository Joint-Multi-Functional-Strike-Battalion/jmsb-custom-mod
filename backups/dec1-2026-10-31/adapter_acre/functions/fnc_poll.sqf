#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every POLL_S: each ACRE radio this player carries becomes an RF
 * node (rf_register) with the profile its base class maps to, on DATA only,
 * and is unregistered when it is gone (RF does not grade ACRE voice: ACRE's
 * own signal model does). Then the voice API's view of his radios is rebuilt
 * (fnc_voiceView).
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], -1] call jmfsb_adapter_acre_fnc_poll
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

if (isNull player || {isNil "acre_api_fnc_getCurrentRadioList"}) exitWith {};

private _uid = getPlayerUID player;
private _seen = [];
{
    private _base = [_x] call acre_api_fnc_getBaseRadio;
    private _i = ACRE_PROFILES findIf {(_x select 0) == _base};
    private _profile = if (_i >= 0) then {(ACRE_PROFILES select _i) select 1} else {ACRE_PROFILE_DEFAULT};
    private _id = format [NODE_ID_FORMAT, _uid, _x];
    _seen pushBack _id;

    private _reg = [player, _profile, [NET_DATA], _id, OWNER_TAG, player];
    if ((GVAR(sent) getOrDefault [_id, []]) isNotEqualTo _reg) then {
        _reg call EFUNC(rf,register);
        GVAR(sent) set [_id, _reg];
    };
} forEach ([] call acre_api_fnc_getCurrentRadioList);

{
    [_x] call EFUNC(rf,unregister);
    GVAR(sent) deleteAt _x;
} forEach ((keys GVAR(sent)) - _seen);

[] call FUNC(voiceView);
