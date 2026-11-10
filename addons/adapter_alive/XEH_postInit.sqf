#include "script_component.hpp"

// SLICE ZERO (docs/new.md section 9). Four probes.
//
// Registered as CBA chat commands, NOT through jmfsb's own "#jmfsb " debug
// channel: that channel is gated on jmfsb_common_isAdmin, which is only set
// after a successful #login, which needs CBA's IS_ADMIN - and IS_ADMIN is
// false in an editor preview. A probe that cannot run in the environment the
// mission is actually tested in is worthless, so these use the same mechanism
// jmfsb's own #login uses and work in singleplayer, hosted and dedicated.
//
// ADMINS ONLY (review S7). Anyone could type them, and they went on a CBA
// event any client could raise: a squad spawned and a fire mission called by
// any player. Now they go by remoteExec to FUNC(probe), which takes them only
// from an admin by the server's records - the host and a single player are
// the server and pass; on a dedicated server, #login first.
//
//   #jmfsbreads     commanders, controltype, TAORs, AA pool
//   #jmfsbsquad     spawn -> profile -> waypoint
//   #jmfsbfire      one ARTY_REQUEST
//   #jmfsbcapture   hold a test objective, see the capture event
//
// Typed on a client; the work happens on the server, where ALiVE's registries
// live. Written out one by one rather than generated: a macro inside a format
// string is not expanded by the preprocessor, and the generated version looked
// correct while registering nothing.

if (hasInterface) then {
    ["jmfsbreads", {
        ["alive.reads"] remoteExecCall [QFUNC(probe), SERVER_OWNER];
    }, "all"] call CBA_fnc_registerChatCommand;

    ["jmfsbsquad", {
        ["alive.squad"] remoteExecCall [QFUNC(probe), SERVER_OWNER];
    }, "all"] call CBA_fnc_registerChatCommand;

    ["jmfsbfire", {
        ["alive.fire"] remoteExecCall [QFUNC(probe), SERVER_OWNER];
    }, "all"] call CBA_fnc_registerChatCommand;

    ["jmfsbcapture", {
        ["alive.capture"] remoteExecCall [QFUNC(probe), SERVER_OWNER];
    }, "all"] call CBA_fnc_registerChatCommand;

    // Not slice zero - a read-only answer to ALiVE's repeating combat-simulator
    // errors, which name ALiVE's own file and never the vehicle behind them.
    ["jmfsbdamage", {
        ["alive.damage"] remoteExecCall [QFUNC(probe), SERVER_OWNER];
    }, "all"] call CBA_fnc_registerChatCommand;

    // Server frame rate and what is on the map, on demand. Diagnosing "the
    // lag" from an RPT after the run is guesswork; this measures it while it
    // is happening.
    ["jmfsbperf", {
        ["perf"] remoteExecCall [QFUNC(probe), SERVER_OWNER];
    }, "all"] call CBA_fnc_registerChatCommand;

    // TRAINING HOLD. A mission with the JMSB - Hold ALiVE module starts with
    // ALiVE paused; this starts it. Admins only - FUNC(hold) checks the sender.
    ["jmfsbalivestart", {
        [false] remoteExecCall [QFUNC(hold), SERVER_OWNER];
    }, "all"] call CBA_fnc_registerChatCommand;
};

// NO SUPPORT PROVIDER (user, 2026-11-02: "if alive is present we integrate -
// but not the support"). ALiVE's NEO combat support and its ATO are not
// support assets: TAC//MSG lists the mod's own providers only, the same with
// or without ALiVE. Nothing here registers with the support core.

if (!isServer) exitWith {};

[] call FUNC(ready);
// ALiVE's AA fallback lists stock A3 factions only - ours would spawn no air
// defence at all with an empty picker. See the function.
[] call FUNC(registerFactionAA);

// POOL SIZES, PUBLISHED. A device draws its own buttons and cannot ask the
// server what is worth offering, so the two counts go public on a slow beat.
// Counts only - never the contents, which stay server-side where a client
// cannot read the enemy's positions out of a variable. Started once, from
// FUNC(whenReady) - not the ready CBA event any client could raise again
// (review R1).
//
// No fallback (user, 2026-11-02: "same as not loaded"): when FUNC(ready) gives
// up on a mission with no commander, nothing here starts - no pools, no
// bridge, no COP or LAMBS settings - exactly as when this PBO is not loaded.
// The counts stay unset, which every reader takes as 0.
[{
    [{
        // ONE HEAVY WALK PER TICK, NOT ALL OF THEM. aaTargets, artyTargets,
        // camps and radars each walk the whole profile system with config
        // lookups; doing the four on the same beat was a hitch every POOL_TICK
        // - the periodic lag spike. They change slowly (a count for a button),
        // so they take turns: one per tick, each refreshed every four ticks.
        // The cheap publishes below still run every tick.
        private _phase = missionNamespace getVariable [QGVAR(poolPhase), 0];
        missionNamespace setVariable [QGVAR(poolPhase), (_phase + 1) mod 4];
        switch (_phase) do {
            case 0: { missionNamespace setVariable [QGVAR(aaCount), count (call FUNC(aaTargets)), true] };
            case 1: { missionNamespace setVariable [QGVAR(artyCount), count ([sideUnknown] call FUNC(artyTargets)), true] };
            case 2: { missionNamespace setVariable [QGVAR(campCount), count ((call FUNC(camps)) select {(_x select 3) isNotEqualTo sideUnknown}), true] };
            case 3: { missionNamespace setVariable [QGVAR(radarCount), count (call FUNC(radars)), true] };
        };

        // hubCount reads the supply-network hash, which is small - every tick.
        missionNamespace setVariable
            [QGVAR(hubCount), count (call FUNC(logisticsHubs)), true];

        // THE CLIENT-SAFE SUMMARY. FUNC(commanders) and FUNC(taorFor) read
        // ALiVE's server-side hashes, so on a dedicated client both came
        // back empty - which made hacking's taorType answer "" and every
        // hack offer NO products to remote players. Sides, control types,
        // factions and marker NAMES go public - never positions, never the
        // instances. Both functions fall back to these when they cannot ask.
        missionNamespace setVariable [QGVAR(commandersPub),
            (call FUNC(commanders)) apply {
                _x params ["_s", "_t", "_f"];
                [_s, _t, _f]
            }, true];
        missionNamespace setVariable [QGVAR(taorPub),
            [west, east, independent] apply {
                [_x] + ([_x] call FUNC(taorFor))
            }, true];
    }, POOL_TICK, []] call CBA_fnc_addPerFrameHandler;

    // ALiVE'S EVENTS BECOME JMFSB'S. See FUNC(eventBridge).
    [] call FUNC(eventBridge);

    // ONE CORPSE, ONE KIND OF INTEL. ALiVE drops "Read intel" files on the
    // dead with its own chance (mil_opcom fnc_OPCOMdropIntel.sqf:37, per-side
    // ALiVE_MIL_OPCOM_INTELCHANCE_<side>); jmfsb's bodies already carry the
    // phones, radios and documents the intel economy runs on. Two systems
    // handing out intel for the same corpse doubles the take and splits the
    // picture, so ALiVE's chance is set to zero for every commander and the
    // find goes through jmfsb - which now reports it back to ALiVE's G2
    // (FUNC(reportIntel)). ALiVE's file is not deleted from ALiVE; it is
    // simply never rolled.
    {
        _x params ["_cside"];
        missionNamespace setVariable [format ["ALiVE_MIL_OPCOM_INTELCHANCE_%1", _cside], 0, true];
    } forEach (call FUNC(commanders));

    // THE COP DRAWS INSTALLATIONS ONLY WHEN ASKED. Every one of ALiVE's
    // asymmetric infrastructure layers defaults off (mil_c2istar cop
    // fnc_COPConfig.sqf:200-206) and the server skips collecting them when
    // all are off (fnc_COPAsym.sqf:119-125). JMSB's whole asymmetric hunt is
    // those installations; a tablet that cannot show them is missing the
    // point, so the four jmfsb hunts are switched on.
    //
    // Set outright and broadcast: the server reads them to collect, but each
    // client reads its own copy to draw (fnc_COPRender.sqf:613-627), and
    // every machine's COPConfig has already seeded them false - so an isNil
    // guard cannot tell a mission's choice from ALiVE's default, and a
    // server-only set leaves every dedicated client drawing nothing. The
    // JIP-persistent value also beats a late client's COPConfig, which only
    // fills in what is still nil.
    {
        missionNamespace setVariable [_x, true, true];
    } forEach ["ALIVE_COP_ASYM_SHOW_HQ", "ALIVE_COP_ASYM_SHOW_FACTORY", "ALIVE_COP_ASYM_SHOW_DEPOT", "ALIVE_COP_ASYM_SHOW_ROADBLOCK"];

    // The intel reveal is a C2ISTAR / Military Intel module attribute that
    // ALiVE publishes itself; it is only defaulted on when no module set it.
    if (isNil "ALIVE_militaryIntelRevealInstallations") then {
        missionNamespace setVariable ["ALIVE_militaryIntelRevealInstallations", true, true];
    };

    // LAMBS OFF FOR EVERY COMBAT-SUPPORT AIRFRAME. ALiVE tags each asset it
    // stands up with ALIVE_CombatSupport, so that tag is the whole list -
    // no guessing at classes and nothing to keep in step when a mission
    // changes its airframes. LAMBS' infantry reflexes make a transport
    // break off a pickup to take cover and a CAS pass turn into an
    // autonomous manoeuvre; a support aircraft flies the task it was given.
    //
    // On the same slow beat as the pools, because assets respawn and
    // rejoin: an airframe that came back after being shot down is a new
    // object with LAMBS' defaults on it. FUNC(lambsOff) marks what it has
    // done, so this only ever pays for the new ones.
    [{
        {
            [_x] call EFUNC(common,lambsOff);
        } forEach (vehicles select {
            _x getVariable ["ALIVE_CombatSupport", false]
            && {!(_x getVariable [QEGVAR(common,lambsOff), false])}
        });
    }, POOL_TICK, []] call CBA_fnc_addPerFrameHandler;
}] call FUNC(whenReady);

