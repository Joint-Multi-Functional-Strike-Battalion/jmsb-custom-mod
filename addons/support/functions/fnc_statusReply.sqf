#include "script_component.hpp"
/*
 * Author: YonV
 * Server: an asset answers STATUS in its thread (docs/DESIGN_MESSAGE_TEMPLATES.md,
 * 2026-11-09: "report position, current task, time left on station, fuel,
 * ammo and pax") with a STATUS REPLY card, filed as the asset
 * (FUNC(fileCard)). From FUNC(srvFollowUp); the provider is not told.
 *
 * WHAT IT SAYS. The provider's optional "status" hook - [assetId, threadId]
 * -> [vehicle, task text, minutes left on station (-1 none)] - gives the
 * vehicle, what it is doing and how long it can stay; without one the task
 * is the provider's sitrep line and nothing is said about the time. From the
 * vehicle the core reads the rest: its grid and altitude, its fuel as a
 * percentage, its ordnance (FUNC(ordnanceLeft)) and the men in its cargo
 * seats. No vehicle (a battery's virtual guns, an aircraft not yet made):
 * those lines are left out.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["air:0", "T0042"] call jmfsb_support_fnc_statusReply
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_threadId", "", [""]]];

if (!isServer || _assetId isEqualTo "" || _threadId isEqualTo "") exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("statusReply: refused - remote call from machine %1",remoteExecutedOwner);
};

([_assetId] call FUNC(provider)) params ["_kind", "_decl"];
if (_kind isEqualTo "") exitWith {};

private _veh = objNull;
private _task = "";
private _minutes = -1;
private _hook = _decl getOrDefault ["status", {}];
if (_hook isNotEqualTo {}) then {
    private _said = [_assetId, _threadId] call _hook;
    if (!isNil "_said" && {_said isEqualType []} && {count _said >= STATUS_HOOK_FIELDS}) then {
        _said params [["_v", objNull, [objNull]], ["_t", "", [""]], ["_m", -1, [0]]];
        _veh = _v;
        _task = _t;
        _minutes = _m;
    };
};
if (_task isEqualTo "") then {
    private _sitrep = _decl getOrDefault ["sitrep", {}];
    if (_sitrep isNotEqualTo {}) then {
        private _line = [_assetId] call _sitrep;
        if (!isNil "_line" && {_line isEqualType []}) then {_task = _line param [1, ""]};
        if !(_task isEqualType "") then {_task = ""};
    };
};

private _payload = [[STATUS_KEY_TASK, toUpper _task]];
if (_minutes >= 0) then {_payload pushBack [STATUS_KEY_TIME, format [STATUS_TIME_FORMAT, round _minutes]]};
if (alive _veh) then {
    _payload pushBack [STATUS_KEY_POSITION, format ["%1 %2M", mapGridPosition _veh, round ((getPosATL _veh) select 2)]];
    _payload pushBack [STATUS_KEY_FUEL, format [STATUS_FUEL_FORMAT, round (fuel _veh * STATUS_PERCENT)]];
    _payload pushBack [STATUS_KEY_AMMO, [_veh] call FUNC(ordnanceLeft)];
    private _pax = count ((fullCrew [_veh, "cargo", false]) select {alive (_x select 0)});
    _payload pushBack [STATUS_KEY_PAX, [str _pax, STATUS_NONE] select (_pax isEqualTo 0)];
};

[_assetId, _threadId, CARD_STATUS_REPLY, _payload] call FUNC(fileCard);
