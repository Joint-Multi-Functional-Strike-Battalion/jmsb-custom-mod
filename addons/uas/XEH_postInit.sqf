#include "script_component.hpp"

// THE REPORT, admins only, answered to the caller alone (review R1: it was a
// CBA event any player could raise to print the enemy's drone picture in
// everyone's chat). On the #jmfsb surface: registered on every machine,
// because the typer's machine looks it up, and run on the server. #jmfsbuas is
// a shortcut to `#jmfsb uas`.
["uas", "drone patrols against their ceiling, and outages", {
    // Built with an explicit loop rather than `apply` over the hashmaps:
    // apply is an ARRAY command, and running it on a HashMap threw before
    // this could print anything at all - which is why the command looked
    // like it did nothing.
    private _fleet = [];
    {
        private _side = _x;
        private _want = 0;
        {
            _want = _want + ([_side, _x # 5] call FUNC(ceilingFor));
        } forEach ([_side] call FUNC(zonesFor));

        _fleet pushBack format ["%1=%2/%3", _side, [_side] call FUNC(livePatrols), _want];
    } forEach [west, east, independent];

    private _out = [];
    {
        _out pushBack format ["%1 for %2s", _x, round (_y - CBA_missionTime)];
    } forEach GVAR(outages);

    private _txt = format ["patrols/ceiling %1 | outages %2",
        _fleet, ["none", str _out] select (_out isNotEqualTo [])];
    diag_log text format ["[jmfsb_uas] %1", _txt];
    format ["UAS: %1", _txt]
}] call EFUNC(common,addDebugCommand);

if (hasInterface) then {
    ["jmfsbuas", {
        ["#jmfsb uas", player] call EFUNC(common,debugCommand);
    }, "all"] call CBA_fnc_registerChatCommand;
};

if (!isServer) exitWith {};

// side text -> time the outage ends. Read by FUNC(ceilingFor).
GVAR(outages) = createHashMap;
// side text -> [profileID, ...] of the patrols that side is flying.
GVAR(patrols) = createHashMap;
// Sides whose drones ALiVE declined to profile, so the reason is logged once
// rather than once per airframe. See FUNC(topUp).
GVAR(unprofilable) = [];
// Sides skipped for being on the players' team, said once each rather than
// every planning tick. See FUNC(planPatrols).
GVAR(friendlySaid) = [];

// A ZONE IS THE ENABLE. This file only sets up state and the report command;
// the first JMSB - Drone Patrol Zone module to arm is what starts the system,
// so a mission that draws no zone gets nothing from this addon.
// GVAR(moduleUp) is declared in XEH_preInit, NOT here - see there for why.

// ...AND AN ALiVE OBJECTIVE IS A ZONE, if the mission asked for that. Off by
// default; QGVAR(aliveZones) is the opt-in that stands where jmfsb's deleted
// JMSB - UAS module stood. Both paths are covered because a commander can
// come up either side of this file running: if the adapter is already ready the
// zones are taken now, otherwise on its ready event, which fires once.
//
// Objective ids already turned into zones. FUNC(zonesFromAlive) reads it so a
// late commander adds only what is new.
GVAR(aliveZoneIds) = [];

// The adapter's whenReady runs it now when ready already, and once only - not
// the ready CBA event any client could raise again (review R1).
//
// Without ALiVE there are no objectives to patrol (user, 2026-11-02): said
// once when the opt-in is on, and Drone Patrol Zone modules fly as they do
// with it. The same branch when ALiVE is loaded with no commanders ("same as
// not loaded"): the adapter's fallback, once it gives up.
private _without = {
    [{
        if (GVAR(aliveZones)) then {
            ["UAS objective zones", "off - Drone Patrol Zone modules only"] call EFUNC(common,aliveLoaded);
        };
    }] call EFUNC(common,runAfterSettingsInit);
};
if (!isNil QEFUNC(adapter_alive,whenReady)) then {
    [{ [] call FUNC(zonesFromAlive) }, [], _without] call EFUNC(adapter_alive,whenReady);
} else {
    call _without;
};

// The report is the #jmfsb uas admin command (top of this file).

// THE IED PELICAN IS DDT'S TO FLY. Drongo's Drone Tweaks gives the AI drones
// from its own class lists; ours is not on them, so it goes on once DDT has
// built them (ddtReady). ddtClassesFPV is "fly it into something soft";
// its InArray is case-insensitive, so the spelling here is only for reading.
// No DDT in the load order: nothing waits, nothing breaks - the timeout is
// there so the wait does not sit forever in a mission without it.
[{missionNamespace getVariable ["ddtReady", false]}, {
    ddtClassesFPV pushBackUnique QGVAR(UAV_06_IED_I);
    diag_log text "[jmfsb_uas] IED Pelican registered with Drongo's Drone Tweaks as an FPV";
}, [], 600] call CBA_fnc_waitUntilAndExecute;
