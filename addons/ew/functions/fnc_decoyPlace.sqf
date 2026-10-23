#include "script_component.hpp"
/*
 * Author: JMSB
 * EA: places a decoy at a man's feet (DESIGN_EW "Decoy"; ISR only). The
 * decoy is a ground antenna registered in RF with a chosen profile's band and
 * power, claiming one net under a key nobody else holds - so it carries no
 * traffic, relays nothing, links with nobody, and ES hears a set of that
 * profile. Its node carries intent "decoy", the drone40 decoy's mark, so
 * both are the same thing to EW. Its battery is the decoy setting; then it
 * goes. Two per man. On a client this forwards to the server.
 *
 * Arguments:
 * 0: Operator <OBJECT>
 * 1: Profile to copy, one of DECOY_PROFILES <STRING>
 * 2: Net to claim ("" = the first voice net he holds, else DATA) <STRING>
 *
 * Return Value:
 * Node id (server), "" when refused or forwarded <STRING>
 *
 * Example:
 * [player, "handheld", ""] call jmfsb_ew_fnc_decoyPlace
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_profile", "handheld", [""]], ["_net", "", [""]]];

if (!isServer) exitWith {
    [QGVAR(decoyPlace), [_unit, _profile, _net]] call CBA_fnc_serverEvent;
    ""
};
if (isNull _unit || {!alive _unit}) exitWith {""};

private _uid = getPlayerUID _unit;
private _refuse = switch (true) do {
    case (!(([_unit] call FUNC(kit)) get "isr")): {"DECOYS ARE FOR ISR OPERATORS"};
    case (!(_profile in DECOY_PROFILES)): {"NO SUCH PROFILE TO COPY"};
    case (({(_x select 1) isEqualTo _uid} count (values GVAR(decoys))) >= DECOYS_PER_MAN): {format ["%1 DECOYS OUT ALREADY", DECOYS_PER_MAN]};
    default {""};
};
if (_refuse isNotEqualTo "") exitWith {
    [_unit, "EA", _refuse, ""] call FUNC(warn);
    ""
};

if (_net isEqualTo "") then {
    private _nets = [];
    {
        {_nets pushBackUnique (_x select 0)} forEach (_x select 3);
    } forEach ([_unit, []] call EFUNC(rf,nodesFor));
    _net = ((_nets - [NET_DATA]) param [0, NET_DATA]);
};

private _pos = _unit getRelPos [2, 0];
private _prop = createVehicle [DECOY_CLASS, _pos, [], 0, "CAN_COLLIDE"];
if (isNull _prop) exitWith {""};

GVAR(nextDecoy) = GVAR(nextDecoy) + 1;
private _id = format ["ew_decoy_%1", GVAR(nextDecoy)];
[
    _prop, _profile, [[_net, format [DECOY_KEY_FORMAT, _id]]], _id, OWNER_TAG, objNull,
    side group _unit, [[INTENT_KEY, INTENT_DECOY]]
] call EFUNC(rf,register);
[_id, [["relay", false], ["tx", false]]] call EFUNC(rf,setState);

GVAR(decoys) set [_id, [_prop, _uid, CBA_missionTime + GVAR(decoyLife)]];
[_unit, "EA", format ["DECOY UP: %1 ON %2", toUpper _profile, _net], format ["BATTERY %1 MIN", round (GVAR(decoyLife) / 60)]] call FUNC(warn);
[[_unit], false] call FUNC(publish);
_id
