#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a hack finished on a tablet (FUNC(hackComplete), by remoteExec).
 * What the client says is checked before anything happens (review S7):
 * - the operator is the sender's own unit, and his side is his group's;
 * - he may hack that device as that kind (FUNC(srvMayHack): range, gate,
 *   what the object really is, not broken already);
 * - the hack really ran: the server saw it start (FUNC(srvHackStart)) at
 *   least most of the kind's clock ago (FUNC(hackDuration));
 * - the product is one the device offers (FUNC(intelOptions), run here).
 * The position is the device's, never one from the request. Then the server
 * does the kind's work: downs the drone, strips the wreck, breaks the net -
 * sending the failure package, or the SPOOF, when that is what the client's
 * rolls said - or books the tower, and pulls the product (FUNC(serverPick)).
 * A refusal is said on the sender's screen.
 *
 * Arguments:
 * 0: The device <OBJECT>
 * 1: Kind, "tower" | "drone" | "wreck" | "unit" <STRING>
 * 2: The product picked, "none" for a drone <STRING>
 * 3: Outcome of a unit hack: HACK_ACTION_DEFAULT, HACK_ACTION_SPOOF or
 *    HACK_OUTCOME_DETECTED (optional, default HACK_ACTION_DEFAULT) <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_device, "tower", "aa"] remoteExecCall ["jmfsb_hacking_fnc_srvHackComplete", 2]
 *
 * Public: No
 */

params [["_device", objNull, [objNull]], ["_kind", "", [""]], ["_intel", "", [""]], ["_outcome", HACK_ACTION_DEFAULT, [""]]];

if (!isServer) exitWith {};

// Read before anything else: the sender is known only here (review S7).
([] call EFUNC(common,sender)) params ["_owner", "_unit"];

private _fnc_refuse = {
    params ["_why"];
    WARNING_4("srvHackComplete: %1 refused on %2 (%3) - %4",_unit,_device,_kind,_why);
    if (!isNull _unit) then {
        ["Hack", format ["Intrusion refused - %1.", _why], HACK_REFUSED_COLOR] remoteExecCall [QEFUNC(notify,notify), _owner];
    };
};

private _why = [_unit, _device, _kind] call FUNC(srvMayHack);
if (_why isNotEqualTo "") exitWith {[_why] call _fnc_refuse};

private _starts = localNamespace getVariable [QGVAR(srvStarts), createHashMap];
private _key = _device call BIS_fnc_netId;
private _need = ([_kind] call FUNC(hackDuration)) * HACK_SERVER_TIME_SLACK;
if (!(_key in _starts) || {(CBA_missionTime - (_starts get _key)) < _need}) exitWith {
    ["the hack did not run its course"] call _fnc_refuse;
};

// The products this device offers, asked here as the tablet asked. The
// tablet's list is a global on a hosted server's own screen: kept as it was.
private _keep = GVAR(intelAvailable);
private _session = createHashMapFromArray [["kind", _kind], ["device", _device], ["intel", _intel]];
private _offered = ([_session] call FUNC(intelOptions)) apply {_x select 0};
GVAR(intelAvailable) = _keep;
private _tap = _kind isNotEqualTo "unit" || _outcome isEqualTo HACK_ACTION_DEFAULT;
if (_tap && {_offered isNotEqualTo []} && {!(_intel in _offered)}) exitWith {
    ["that product is not on this device"] call _fnc_refuse;
};

_starts deleteAt _key;
private _done = localNamespace getVariable [QGVAR(srvDone), createHashMap];
private _side = side group _unit;

switch (_kind) do {
    // The hack IS the effect: down it silently, crew and all.
    case "drone": {
        _done set [_key, true];
        _device setVariable [QGVAR(hacked), true, true];
        {deleteVehicle _x} forEach (crew _device);
        deleteVehicle _device;
    };

    case "wreck": {
        _done set [_key, true];
        _device setVariable [QGVAR(stripped), true, true];
        [_intel, getPosASL _device, _side, _unit, _device] call FUNC(serverPick);
    };

    // THE WHOLE NET GOES, not the one handset (FUNC(hackComplete)).
    case "unit": {
        private _grp = group ([_device, effectiveCommander _device] select !(_device isKindOf "CAManBase"));
        _done set [_grp call BIS_fnc_netId, true];
        _grp setVariable [QGVAR(hacked), true, true];
        {_x setVariable [QGVAR(hacked), true, true]} forEach (units _grp);

        switch (true) do {
            // The failure package lands on the sender, where he stands.
            case (_outcome isEqualTo HACK_OUTCOME_DETECTED): {
                [_unit, getPosASL _unit] call FUNC(remoteHackFail);
            };
            case (_outcome isEqualTo HACK_ACTION_SPOOF && {!isNil QEFUNC(ew,spoofNode)}): {
                [_grp, _unit] call EFUNC(ew,spoofNode);
            };
            default {
                [_intel, getPosASL _device, _side, _unit, _device] call FUNC(serverPick);
            };
        };
    };

    default {
        private _towers = localNamespace getVariable [QGVAR(srvTowerAt), createHashMap];
        _towers set [_key, CBA_missionTime];
        localNamespace setVariable [QGVAR(srvTowerAt), _towers];
        _device setVariable [QGVAR(hacked), true, true];
        _device setVariable [QGVAR(lastHack), CBA_missionTime, true];
        [_intel, getPosASL _device, _side, _unit, _device] call FUNC(serverPick);
    };
};

localNamespace setVariable [QGVAR(srvDone), _done];
INFO_5("hack complete: %1 %2 by %3 - %4 %5",_kind,_device,name _unit,_intel,_outcome);
