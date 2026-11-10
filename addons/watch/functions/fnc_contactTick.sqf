#include "script_component.hpp"
/*
 * Author: YonV
 * The server's once-a-second pass over the contacts (design sync.los_checks):
 * does any friendly player of the spotter's side, within SHARE_RANGE, have
 * line of sight? Then the contact's position is fresh and every friendly in
 * range sees it solid. Lost longer than the drop time (server setting) - or
 * dead, or gone - it is forgotten. The list goes to every client as
 * GVAR(contactList), [object, kind, side, group, last ASL, last seen, LOS,
 * shared until], when it changed.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_watch_fnc_contactTick
 *
 * Public: No
 */

if (!isServer) exitWith {};

private _players = allPlayers - entities "HeadlessClient_F";
private _drop = GVAR(dropMinutes) * 60;
{
    private _key = _x;
    _y params ["_obj", "_kind", "_side", "", "", "_seen"];
    if (isNull _obj || {_kind isEqualTo "recon" && {!alive _obj}}) then {GVAR(contacts) deleteAt _key; continue};
    private _aim = (getPosASL _obj) vectorAdd [0, 0, LOS_AIM_UP];
    private _los = (_players findIf {
        alive _x && {side group _x isEqualTo _side} && {(_x distance _obj) <= SHARE_RANGE}
        && {([_x, "VIEW", _obj] checkVisibility [eyePos _x, _aim]) > LOS_VISIBLE}
    }) >= 0;
    _y set [6, _los];
    if (_los) then {
        _y set [4, getPosASL _obj];
        _y set [5, serverTime];
    } else {
        if ((serverTime - _seen) > _drop) then {GVAR(contacts) deleteAt _key};
    };
} forEach +GVAR(contacts);

private _list = (values GVAR(contacts)) apply {_x select [0, 8]};
if (_list isNotEqualTo GVAR(contactList)) then {
    GVAR(contactList) = _list;
    publicVariable QGVAR(contactList);
};
