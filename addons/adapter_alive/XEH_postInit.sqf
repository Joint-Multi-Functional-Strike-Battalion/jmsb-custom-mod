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
        [QGVAR(run), ["alive.reads", player]] call CBA_fnc_serverEvent;
    }, "all"] call CBA_fnc_registerChatCommand;

    ["jmfsbsquad", {
        [QGVAR(run), ["alive.squad", player]] call CBA_fnc_serverEvent;
    }, "all"] call CBA_fnc_registerChatCommand;

    ["jmfsbfire", {
        [QGVAR(run), ["alive.fire", player]] call CBA_fnc_serverEvent;
    }, "all"] call CBA_fnc_registerChatCommand;

    ["jmfsbcapture", {
        [QGVAR(run), ["alive.capture", player]] call CBA_fnc_serverEvent;
    }, "all"] call CBA_fnc_registerChatCommand;

    // Not slice zero - a read-only answer to ALiVE's repeating combat-simulator
    // errors, which name ALiVE's own file and never the vehicle behind them.
    ["jmfsbdamage", {
        [QGVAR(run), ["alive.damage", player]] call CBA_fnc_serverEvent;
    }, "all"] call CBA_fnc_registerChatCommand;

    // Server frame rate and what is on the map, on demand. Diagnosing "the
    // lag" from an RPT after the run is guesswork; this measures it while it
    // is happening.
    ["jmfsbperf", {
        [QGVAR(run), ["perf", player]] call CBA_fnc_serverEvent;
    }, "all"] call CBA_fnc_registerChatCommand;
};

// ---------------------------------------------------------------------------
// ALiVE COMBAT SUPPORT AS A SUPPORT PROVIDER. The support core owns the
// registry, the gate and the request flow; this registers ALiVE's NEO assets
// and the ATO's one row as provider "alive", so every ALiVE name stays in this
// addon. Ids are "alive:<type>:<index>" and "alive:ato". The AI commander's
// artillery is deliberately absent - see the note at the ATO publish loop below.
// An ATO task is a server event, because the request has to be raised on the
// machine that holds ALiVE's event log.
//
// ON EVERY MACHINE, ABOVE THE SERVER-ONLY EXIT: TAC//SUPPORT is drawn on the
// client and reads its rows locally. (The old ATO provider sat below that exit
// and so only ever reached the server's own screen.)
[SUPPORT_KIND, createHashMapFromArray [
    ["assets", FUNC(supportAssets)],
    ["task", FUNC(supportTask)],
    ["sitrep", FUNC(supportSitrep)],
    ["types", call FUNC(supportTypes)]
]] call EFUNC(support,registerProvider);

if (!isServer) exitWith {};

[] call FUNC(ready);
// ALiVE's AA fallback lists stock A3 factions only - ours would spawn no air
// defence at all with an empty picker. See the function.
[] call FUNC(registerFactionAA);

[QGVAR(run), {
    params [["_which", "", [""]], ["_caller", objNull, [objNull]]];
    [_which, _caller] call FUNC(probe);
}] call CBA_fnc_addEventHandler;

// POOL SIZES, PUBLISHED. A device draws its own buttons and cannot ask the
// server what is worth offering, so the two counts go public on a slow beat.
// Counts only - never the contents, which stay server-side where a client
// cannot read the enemy's positions out of a variable.
[QGVAR(ready), {
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

        // The ATO presence flag is all the support app needs from ALiVE now -
        // the battery registry is deliberately NOT published: listing every
        // AI-commander gun made the app a directory of assets the player
        // cannot actually task (ARTY_REQUEST picks its own battery, and only
        // where a friendly artillery module exists at all).
        missionNamespace setVariable [QGVAR(atoPub),
            (allMissionObjects ATO_CLASS) apply {toUpper (_x getVariable ["side", ""])}, true];
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
}] call CBA_fnc_addEventHandler;

if (isServer) then {
    [QGVAR(supportRequest), {
        params ["_kind", "_side", "_pos", "_who"];
        private _ok = switch (_kind) do {
            case "cas":  { [_side, _pos] call FUNC(requestCAS) };
            default { false };
        };
        INFO_4("support request %1 by %2 for %3 -> %4",_kind,_who,_side,_ok);
    }] call CBA_fnc_addEventHandler;
};

