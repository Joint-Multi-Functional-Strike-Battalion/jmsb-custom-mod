#include "script_component.hpp"

// THE ENEMY'S GUNS (FUNC(cbRadar)): any artillery piece firing with an AI
// gunner, on the machine it is local to - server or headless client - asks
// the server once per CB_RADAR_LOCAL_GAP seconds. A player's gun is the other
// way round: it is counter-batteried (the hook below), never reported.
["LandVehicle", "fired", {
    params [["_gun", objNull, [objNull]]];
    if (!local _gun || {getNumber (configOf _gun >> "artilleryScanner") <= 0}) exitWith {};
    if (isPlayer (gunner _gun)) exitWith {};
    if (CBA_missionTime < (_gun getVariable [QGVAR(cbRadarAsked), -1e9]) + CB_RADAR_LOCAL_GAP) exitWith {};
    _gun setVariable [QGVAR(cbRadarAsked), CBA_missionTime];
    // By remoteExec, so the server can tell it is this machine's gun (review R1).
    [_gun] remoteExecCall [QFUNC(cbRadar), SERVER_OWNER];
}] call CBA_fnc_addClassEventHandler;

if (hasInterface) then {
    [] call FUNC(radioInit);

    // COUNTER-BATTERY, THE PLAYER'S GUN (FUNC(cbShot)). ACE raises this only on
    // the machine of the player who is the gunner, so an AI gun never reaches
    // it - the exception the user asked for (2026-10-25: "not to counter-
    // battery AI arty"). Artillery only: the vehicle's artillery computer.
    ["ace_firedPlayerVehicle", {
        params [["_vehicle", objNull, [objNull]]];
        if (isNull _vehicle || {getNumber (configOf _vehicle >> "artilleryScanner") <= 0}) exitWith {};
        [_vehicle, call CBA_fnc_currentUnit] remoteExecCall [QFUNC(cbShot), SERVER_OWNER];
    }] call CBA_fnc_addEventHandler;
};

// THE REPORT (review L2). An admin command on the #jmfsb surface: registered on
// every machine, because the typer's machine looks it up and the server runs
// it; admins only, and the answer goes to the caller alone. #jmfsbreact is a
// shortcut to `#jmfsb react`.
["react", "flag and cooldown counts, and whether you are flagged", {
    params ["", "_caller"];
    private _txt = format ["flagged=%1 majors=%2 | you: %3",
        count GVAR(flags), count GVAR(majors),
        ["clean", "FLAGGED"] select ([_caller] call FUNC(flagged) select 0)];
    diag_log text format ["[jmfsb_reaction] %1", _txt];
    format ["REACTION: %1", _txt]
}] call EFUNC(common,addDebugCommand);

if (hasInterface) then {
    ["jmfsbreact", {
        ["#jmfsb react", player] call EFUNC(common,debugCommand);
    }, "all"] call CBA_fnc_registerChatCommand;
};

if (!isServer) exitWith {};

// netId -> flagged-until, and netId -> last major. The two pieces of state
// the whole ladder runs on.
// THE MODULE IS THE ENABLE. This file only sets up state and the report
// command; FUNC(moduleController) is what arms the system, so a mission with
// no module placed gets nothing from this addon. GVAR(moduleUp) is declared in
// XEH_preInit, NOT here - see there for why.

GVAR(flags) = createHashMap;
GVAR(majors) = createHashMap;

// THE ONE PATH. A failed hack, a drone that saw somebody, and a detectable
// transmission all roll the same degrees (new.md section 2): the server's own
// sources call FUNC(roll), a client reports its own player by remoteExec to
// FUNC(report). No CBA event (review R1): any client could raise one naming
// anyone.

// COUNTER-BATTERY: a player's gun fired (the client hook above, by remoteExec
// to FUNC(cbShot)). The players' VIRTUAL artillery - TAC//SUPPORT's batteries -
// is the exception and is never counter-batteried (user, 2026-10-25: "player
// side virtual are the exception").
// THE RADAR: an enemy gun fired (the class hook above, by remoteExec to
// FUNC(cbRadar)), and ALL enemy shells besides - every virtual barrage
// (jmfsb_common_fnc_fireBarrage, which only enemy fire uses) is reported from
// a virtual battery (FUNC(cbVirtual)).
[{_this call FUNC(cbVirtual)}] call EFUNC(common,onBarrage);

// "THE ENEMY HAS YOUR POSITION." The enemy commander files spot reports on
// the players like on anyone else, and the adapter reads them back off the
// COP (jmfsb_adapter_alive_fnc_enemyKnowledge). When a report lands within
// REACT_SPOTTED_RANGE of a player, that player's group is told once, then
// left alone for REACT_SPOTTED_COOLDOWN - the point is the warning, not a
// ticker. Server-side, so one read serves everyone.
if (isServer) then {
    GVAR(spottedUntil) = createHashMap;
    [{
        if (isNil "jmfsb_adapter_alive_fnc_enemyKnowledge") exitWith {};
        private _bySide = createHashMap;
        {
            private _grp = group _x;
            if (isNull _grp || {!alive _x}) then {continue};
            private _side = side _grp;
            if (isNil {_bySide get (str _side)}) then {
                _bySide set [str _side, [_side] call jmfsb_adapter_alive_fnc_enemyKnowledge];
            };
            private _known = _bySide get (str _side);
            if (_known isEqualTo []) then {continue};
            private _gid = str _grp;
            if (CBA_missionTime < (GVAR(spottedUntil) getOrDefault [_gid, -1])) then {continue};
            private _at = getPosATL _x;
            private _hit = _known findIf {(_x select 0) distance2D _at <= REACT_SPOTTED_RANGE};
            if (_hit < 0) then {continue};
            GVAR(spottedUntil) set [_gid, CBA_missionTime + REACT_SPOTTED_COOLDOWN];
            (_known select _hit) params ["", "", "", "", "_by"];
            {
                ["SPOTTED", format ["%1 has your position.", _by], NOTE_BAD, _x, getPosATL _x] call EFUNC(notify,broadcast);
            } forEach (units _grp select {isPlayer _x});
        } forEach allPlayers;
    }, REACT_SPOTTED_TICK, []] call CBA_fnc_addPerFrameHandler;
};

