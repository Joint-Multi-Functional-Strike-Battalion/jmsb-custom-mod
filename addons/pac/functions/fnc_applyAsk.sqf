#include "script_component.hpp"
/*
    File: fnc_applyAsk.sqf
    Author: YonV
    Description: A player who is not on the roster asks what the unit wants
        to know and where their own application stands - the tacpad's
        APPLICATION tab (user, 2026-09-10: "if application is forced they
        should have to go to the live tile ... and have an application tab
        there instead of my details"). Server only; the questions are
        published for everyone, their own application answered to them
        (FUNC(applyRecv)).

    Parameters:
        0: Who <OBJECT>

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]]];

if (!isServer || isNull _caller) exitWith {};
// Only the sender's own application (review S5).
if !([_caller] call EFUNC(common,senderIs)) exitWith {};
if ((GVAR(settings) getOrDefault ["sync", "off"]) isNotEqualTo "service") exitWith {
    [createHashMapFromArray [["status", "nodb"]]] remoteExec [QFUNC(applyRecv), owner _caller];
};

[_caller] spawn {
    params ["_caller"];
    private _unit = GVAR(settings) getOrDefault ["unitId", ""];
    private _uid = getPlayerUID _caller;
    if (isNil QGVAR(docCache)) then {GVAR(docCache) = createHashMap};

    [] call FUNC(questionsLoad);

    private _key = _unit + ".application." + _uid;
    // always fresh: an admin may have decided it on the website a minute ago
    ([_key] call FUNC(svcLoad)) params ["_d", "_s"];
    private _app = createHashMapFromArray [["status", "none"]];
    if (_s isEqualTo "ok" && {_d isEqualType createHashMap}) then {
        _app = _d;
        GVAR(docCache) set [_key, _d];
    };
    [_app] remoteExec [QFUNC(applyRecv), owner _caller];
};
