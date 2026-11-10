#include "script_component.hpp"
/*
 * Author: YonV
 * THE STAGING ZONE'S SATELLITE UPLINK (user, 2026-10-20: "can we assume a
 * staging zone ... as a sat uplink"). Puts up, or takes down, the radio base
 * station at a staging zone's centre (jmfsb_pac_fnc_baseStation): it relays
 * the players' nets round the zone and links by satellite, in one hop at any
 * distance, to every patrol base and SAT-capable vehicle of the side under
 * open sky.
 *
 * Staging zones are added on the clients (jmfsb_init_fnc_staging runs for
 * players, a Zeus module on the Zeus's machine), so a client hands this to the
 * server, which makes one station per site whoever reports it. The side is the
 * players' (staging zones are theirs). Off with the setting "Staging zone
 * satellite uplink"; nothing without TAC//PAC and RF.
 *
 * Review R1: a client's report was a CBA event, so any client could put a
 * station up anywhere or take any zone's down. Now a client sends only a
 * position, by remoteExec, and the server takes it from an admin, a Zeus, or
 * when it is a staging marker the server sees itself. Object zones and
 * removals are the server's own calls: addStagingZone and removeStagingZone
 * run on the server too (object inits, and remoteExecs to every machine).
 *
 * Arguments:
 * 0: Zone: its object, or its centre position <OBJECT or ARRAY>
 * 1: Put up (true) or take down (false) (optional, default true) <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_crate] call jmfsb_mission_fnc_stagingUplink
 * [_crate, false] call jmfsb_mission_fnc_stagingUplink
 *
 * Public: No
 */

params [["_zone", objNull, [objNull, []]], ["_up", true, [true]]];

if (!isServer) exitWith {
    if (_up && {_zone isEqualType []}) then {
        [_zone, _up] remoteExecCall [QFUNC(stagingUplink), SERVER_OWNER];
    };
};

private _trusted = true;
if (isRemoteExecuted) then {
    ([] call EFUNC(common,sender)) params ["", "_sender"];
    _trusted = ([] call EFUNC(common,senderIsAdmin))
        || {!isNull _sender && {!isNull getAssignedCuratorLogic _sender}}
        || {_up && {_zone isEqualType []} && {(allMapMarkers findIf {
            private _marker = _x;
            private _name = toLower _marker;
            (STAGING_MARKER_PREFIXES findIf {(_name find _x) isEqualTo 0}) >= 0
            && {((markerPos _marker) distance2D _zone) < STAGING_MATCH_M}
        }) >= 0}};
};
if (!_trusted) exitWith {
    WARNING_1("Staging","stagingUplink refused - machine %1 reported no staging zone the server knows",remoteExecutedOwner);
};

if (!_up) exitWith {
    if (_zone isEqualType objNull && !isNil QEFUNC(pac,baseStationRemove)) then {
        [_zone, QUOTE(ADDON)] call EFUNC(pac,baseStationRemove);
    };
};

if (!(missionNamespace getVariable [QGVAR(stagingSatUplink), true]) || isNil QEFUNC(pac,baseStation)) exitWith {};
[_zone, sideUnknown, QUOTE(ADDON)] call EFUNC(pac,baseStation);
