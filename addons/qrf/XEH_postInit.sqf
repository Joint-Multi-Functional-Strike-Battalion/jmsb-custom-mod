#include "script_component.hpp"

// THE REPORT (review L2). An admin command on the #jmfsb surface: registered on
// every machine, because the typer's machine looks it up and the server runs
// it; admins only, and the answer goes to the caller alone. #jmfsbqrf is a
// shortcut to `#jmfsb qrf`.
["qrf", "the watch list and what is currently held", {
    private _txt = format ["%1 objective(s): %2", count GVAR(watches),
        GVAR(watches) apply {
            format ["%1@%2%3", _x get "name", mapGridPosition (_x get "pos"),
                ["", " HELD"] select (_x get "held")]
        }];
    diag_log text format ["[jmfsb_qrf] %1", _txt];
    format ["QRF: %1", _txt]
}] call EFUNC(common,addDebugCommand);

if (hasInterface) then {
    ["jmfsbqrf", {
        ["#jmfsb qrf", player] call EFUNC(common,debugCommand);
    }, "all"] call CBA_fnc_registerChatCommand;
};

if (!isServer) exitWith {};
// THE MODULE IS THE ENABLE. This file only sets up state and the report
// command; FUNC(moduleController) is what arms the system, so a mission with
// no module placed gets nothing from this addon. GVAR(moduleUp) is declared in
// XEH_preInit, NOT here - see there for why.

GVAR(watches) = [];

// A capture is answered by FUNC(onCaptured), which FUNC(check) calls on the
// server. It was the "captured" CBA event, and any client could raise that one
// to have a QRF sent at any position (review S7).

// THE FRONT LINE MOVES AND EVERYBODY HEARS IT. ALiVE's OPCOM logs every
// objective it takes; the adapter hands that on the moment it happens
// (jmfsb_adapter_alive_fnc_onCapture: [sideText, objectiveID, pos, size]). A
// hostile commander taking ground is news the players should get as the
// commander gets it, not when they walk into it. A server hook, not the
// capture CBA event any client could raise for a fake FRONT line (review R1).
if (isServer && {!isNil QEFUNC(adapter_alive,onCapture)}) then {
    [{
        params ["_sideText", "_objId", "_pos", "_size"];
        if (_pos isEqualTo []) exitWith {};
        private _taker = [_sideText, sideUnknown] call EFUNC(common,sideFromText);
        if (_taker isEqualTo sideUnknown) exitWith {};
        private _playerSides = (allPlayers apply {side group _x}) arrayIntersect [west, east, independent];
        if ((_playerSides findIf {_taker getFriend _x < 0.6}) < 0) exitWith {};
        ["FRONT", format ["%1 has taken the ground at %2.", _sideText, mapGridPosition _pos], [0.831, 0.267, 0.267, 1], sideUnknown, _pos] call EFUNC(notify,broadcast);
    }] call EFUNC(adapter_alive,onCapture);
};
