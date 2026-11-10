#include "script_component.hpp"
/*
 * Author: YonV
 * The jump aircraft as support rows - the "assets" code of provider "jump"
 * (addons/support/README.md; user, 2026-11-02: "change the halo/haho/static
 * app in to a message based one"). TAC//MSG lists each in the SUPPORT group
 * by its call sign; its box is B:SUPPORT:<id>.
 *
 * ONE ROW PER JMSB - JUMP AIRCRAFT MODULE of the viewer's side (user,
 * 2026-11-02: "Jump aircraft module"; FUNC(moduleJump)), "jump:<n>" under the
 * module's call sign - several per side. A side with no module has one row,
 * its own jump aircraft "jump:<side>", SKYTRAIN (FUNC(asset)).
 *
 * ONLY FOR THE PEOPLE THE APP WAS FOR: a squad leader or an admin
 * (FUNC(isJumpmaster)). Anyone else gets no row - no TO entry, no @ mention.
 *
 * A module's row reads its aircraft (virtual until tasked, user 2026-11-02):
 * IDLE - ready, none made - TASKED from the JUMP REQUEST's WILCO to the end of
 * the run (one at a time), REARMING in its cooldown or after a loss while its
 * Respawn Delay runs, RTB while it flies home to be removed; a module with no
 * airframe left (the respawn count) has no row. The aircraft, while one is
 * made - and the run's path - ride on the row (fields 7 and 8, the module's
 * QGVAR(veh) / QGVAR(run)). A side's own row reads TASKED while the viewer's own squad has
 * a run up (the group's QGVAR(run)), with that run's aircraft and path. Both
 * published by FUNC(srvLaunch); the thread's pin draws the run-in, the red and
 * the green light from the aircraft. Asked every 2 s while the picker or a
 * pin wants it: reads only what is published.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Rows, [id, type, callsign, platform, status, ordnance, guns, vehicle, plan] each <ARRAY>
 *
 * Example:
 * call jmfsb_jumpmaster_fnc_assets
 *
 * Public: No
 */

if !([] call FUNC(isJumpmaster)) exitWith {[]};

private _side = side group player;
if !(_side in JUMP_SIDES) exitWith {[]};

private _ids = ([_side] call FUNC(modules)) apply {format ["%1%2%3", JUMP_KIND, ID_SEP, _x getVariable [QGVAR(id), -1]]};
if (_ids isEqualTo []) then {_ids = [format ["%1%2%3", JUMP_KIND, ID_SEP, toLower str _side]]};
private _squadRun = (group player) getVariable [QGVAR(run), []];

(_ids apply {
    private _id = _x;
    private _asset = [_id] call FUNC(asset);
    // NO AIRFRAME LEFT (the respawn count, user 2026-11-02): off the list.
    if ((count _asset) isEqualTo 0 || (_asset getOrDefault ["status", ""]) isEqualTo STATUS_EXPENDED) then {
        []
    } else {
        private _logic = _asset get "logic";
        private _run = _squadRun;
        private _status = [STATUS_IDLE, STATUS_TASKED] select (_run isNotEqualTo []);
        if (!isNull _logic) then {
            _run = _logic getVariable [QGVAR(run), []];
            _status = _asset get "status";
        };
        // Made and waiting for its BOARD, the row carries the aircraft (2026-11-02).
        _run params [["_veh", _asset getOrDefault ["veh", objNull], [objNull]], ["_plan", [], [[]]]];
        [
            _id,
            JUMP_TYPE,
            _asset get "callsign",
            toUpper getText (configFile >> "CfgVehicles" >> (_asset get "cls") >> "displayName"),
            _status,
            [],
            0,
            _veh,
            _plan
        ]
    }
}) select {_x isNotEqualTo []}
