#include "script_component.hpp"

// ON TAC//SUPPORT AS A PROVIDER OF THE SUPPORT CORE, kind "air": CAS,
// transport and QRF insertion, one row per placed module. Logistics drops
// are addons/support_logistics' (kind "logi") since 2026-11-01.
// Registered on EVERY machine: the page is drawn on the client and reads its
// rows there. See addons/support/README.md for the contract.
[SUPPORT_KIND, createHashMapFromArray [
    ["assets", FUNC(assets)],
    ["task", FUNC(task)],
    ["sitrep", FUNC(sitrep)],
    ["available", FUNC(assetAvailable)],
    ["tasks", FUNC(tasks)],
    ["preview", FUNC(preview)],
    ["overlay", FUNC(overlay)],
    ["reach", FUNC(reach)],
    // The asset's thread (2026-11-01): the core calls these on the server for
    // a card filed to an aircraft's box and for the issuer's follow-ups.
    ["side", FUNC(side)],
    ["thread", FUNC(srvThread)],
    ["reply", FUNC(threadReply)],
    // STATUS answered by the core (2026-11-09): the aircraft and its task.
    ["status", FUNC(status)],
    // The root cards it takes inside a thread already open (2026-11-02).
    ["threadCards", THREAD_CARDS],
    ["types", SUPPORT_TYPES]
]] call EFUNC(support,registerProvider);

// THE SERVER FLIES EVERYTHING. An order accepted on a client reaches it by
// remoteExec to FUNC(order), never by a CBA event: the server has to know
// who sent it (review S6).

// AI OUT OF A HELICOPTER AND A JUMP, WHERE THE MAN LIVES: the server sends
// FUNC(putOut) and FUNC(jump) to the unit by remoteExec, and they take only
// the server's word (review S7). They were CBA events any client could raise.
//
// WHAT THE SIDE HEARS goes the same way: FUNC(say) on the server sends
// FUNC(sayLocal) to the module's side by remoteExec, taken only from the
// server - the "say" CBA event is gone (review S7).

// ALL IN, AN ACE SELF ACTION ABOARD (user, 2026-11-02: "troop load, all in
// (need an ace interaction while in heli for all in)"). On the helicopter's
// class, so the men inside see it; FUNC(canAllIn) keeps it to a support
// helicopter loading at its pickup and to the request's issuer or a group
// leader. The effect is the server's, by remoteExecCall: FUNC(srvAllIn) checks
// the sender again. ACE is not required - without it the `allin` reply does
// the same.
if (hasInterface && {!isNil "ace_interact_menu_fnc_createAction"}) then {
    private _allIn = [
        QGVAR(allIn), ALL_IN_ACTION_NAME, ALL_IN_ACTION_ICON,
        {[_target] remoteExecCall [QFUNC(srvAllIn), SERVER_OWNER]},
        {[_player, _target] call FUNC(canAllIn)}
    ] call ace_interact_menu_fnc_createAction;
    // WAVE OFF the insertion the same way (2026-11-08, FUNC(canWaveOff)).
    private _waveOff = [
        QGVAR(waveOff), WAVE_OFF_ACTION_NAME, WAVE_OFF_ACTION_ICON,
        {[_target] remoteExecCall [QFUNC(srvWaveOff), SERVER_OWNER]},
        {[_player, _target] call FUNC(canWaveOff)}
    ] call ace_interact_menu_fnc_createAction;
    {
        [_x, 1, ["ACE_SelfActions"], _allIn, true] call ace_interact_menu_fnc_addActionToClass;
        [_x, 1, ["ACE_SelfActions"], _waveOff, true] call ace_interact_menu_fnc_addActionToClass;
    } forEach TRANSPORT_KINDS;
};

// ...AND A SCROLL ACTION (user, 2026-11-06: "hold the landing till told all in
// via message or scroll action"), with or without ACE. On the player, put back
// on every new unit (respawn, Zeus remote control), so one action follows him
// into any helicopter; the same condition and the same server call as the ACE
// one. Shown only while FUNC(canAllIn) holds: aboard a support helicopter
// loading at its pickup, the issuer or a group leader.
if (hasInterface) then {
    ["unit", {
        params ["_unit"];
        if (isNull _unit || {(_unit getVariable [QGVAR(allInAction), -1]) >= 0}) exitWith {};
        private _id = _unit addAction [
            format ["<img image='%1'/> %2", ALL_IN_ACTION_ICON, ALL_IN_ACTION_NAME],
            {
                params ["", "_caller"];
                [vehicle _caller] remoteExecCall [QFUNC(srvAllIn), SERVER_OWNER];
            },
            nil, ALL_IN_ACTION_PRIORITY, true, true, "",
            QUOTE([ARR_2(_this,vehicle _this)] call FUNC(canAllIn))
        ];
        _unit setVariable [QGVAR(allInAction), _id];
    }, true] call CBA_fnc_addPlayerEventHandler;
    // WAVE OFF, the insertion's scroll command (user, 2026-11-08: "on
    // insertion add a wave off scroll command"): the same way, shown only
    // while FUNC(canWaveOff) holds.
    ["unit", {
        params ["_unit"];
        if (isNull _unit || {(_unit getVariable [QGVAR(waveOffAction), -1]) >= 0}) exitWith {};
        private _id = _unit addAction [
            format ["<t color='#ff8040'><img image='%1'/> %2</t>", WAVE_OFF_ACTION_ICON, WAVE_OFF_ACTION_NAME],
            {
                params ["", "_caller"];
                [vehicle _caller] remoteExecCall [QFUNC(srvWaveOff), SERVER_OWNER];
            },
            nil, WAVE_OFF_ACTION_PRIORITY, true, true, "",
            QUOTE([ARR_2(_this,vehicle _this)] call FUNC(canWaveOff))
        ];
        _unit setVariable [QGVAR(waveOffAction), _id];
    }, true] call CBA_fnc_addPlayerEventHandler;
};

// WHAT HAPPENS TO AN AIRFRAME IS SAID IN ITS THREADS (user, 2026-11-05: "needs
// messaging to notify of events like that"): the core's escort watch and this
// addon's own hit watch raise the event with the aircraft; its owner module's
// open threads - the job's and the sortie's, as FUNC(threadState) finds them -
// get the line as a MESSAGE from the asset (EFUNC(support,threadEvent)).
if (isServer) then {
    [QEGVAR(support,aircraftEvent), {
        params [["_veh", objNull, [objNull]], ["_line", "", [""]], ["_flash", false, [false]]];
        private _logic = _veh getVariable [QGVAR(owner), objNull];
        if (isNull _logic || _line isEqualTo "") exitWith {};
        private _ids = [
            (_logic getVariable [QGVAR(job), createHashMap]) getOrDefault ["thread", ""],
            _logic getVariable [QGVAR(sortieThread), ""]
        ] select {_x isNotEqualTo ""};
        private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];
        private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
        {
            [_assetId, _x, _line, _flash, _callsign] call EFUNC(support,threadEvent);
        } forEach (_ids arrayIntersect _ids);
    }] call CBA_fnc_addEventHandler;
};
