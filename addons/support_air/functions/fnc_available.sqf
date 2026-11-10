#include "script_component.hpp"
/*
 * Author: YonV
 * What this asset is doing, as one token, and whether it can take an order -
 * the ONE answer the row, the "available" code and the order all read, so a
 * row that reads idle is never refused.
 *
 * A TRANSPORT IS RE-TASKABLE WHILE IT IS OUT. A helicopter sitting at the LZ
 * waiting for the next order is the normal case, and a row that refused it
 * because it read WAITING would make the second order impossible. Its row
 * still shows what it is doing (not "idle"), so RTB stays armed.
 *
 * VIRTUAL IS READY (user, 2026-11-02: "all support aircraft needs to be
 * virtual till tasked"): a class module with no airframe up is IDLE and takes
 * the order - the airframe is made over the module then. A CAS aircraft out
 * ON STATION takes a reposition from there.
 *
 * NO AIRFRAME LEFT (user, 2026-11-02: "make sure there is a respawn count for
 * each support, default no respawns"): EXPENDED - and the row leaves the
 * SUPPORT list (FUNC(assets)); a card to its box answers WHY_NO_AIRFRAME.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * 0: Can be tasked now <BOOL>
 * 1: Status token <STRING>
 * 2: Why not, "" when it can <STRING>
 *
 * Example:
 * [_logic] call jmfsb_support_air_fnc_available
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[false, "gone", "that asset is gone"]};

private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
private _kind = _logic getVariable [QGVAR(kind), ""];
private _status = _logic getVariable [QGVAR(status), STATUS_IDLE];
private _synced = _logic getVariable [QGVAR(synced), objNull];
private _hadSynced = _logic getVariable [QGVAR(hadSynced), !isNull _synced];

// GONE FOR GOOD: the last airframe it had (FUNC(replace)).
if (_logic getVariable [QGVAR(dead), false]) exitWith {[false, STATUS_EXPENDED, format ["%1 has no airframe left", _callsign]]};

// A synced aircraft is the asset: while it is a wreck, the asset waits for
// its replacement (FUNC(respawn)).
private _respawnAt = _logic getVariable [QGVAR(respawnAt), 0];
private _fnc_replacing = {
    private _left = ceil (_respawnAt - CBA_missionTime);
    [false, STATUS_REPLACING, [format ["%1 is waiting for a replacement aircraft", _callsign], format ["%1 has a replacement aircraft in %2s", _callsign, _left]] select (_left > 0)]
};
if (_hadSynced && {!alive _synced}) exitWith {call _fnc_replacing};

// A QRF that can never fly is spent from the start, not idle: otherwise the
// row reads idle and every task on it is refused.
if (_kind isEqualTo KIND_QRF && {(_logic getVariable [QGVAR(allowed), []]) isEqualTo []}) exitWith {
    [false, STATUS_EXPENDED, format ["%1 can fly none of its insertions", _callsign]]
};
if (_kind isEqualTo KIND_QRF && {!(_logic getVariable [QGVAR(hasSquad), true])}) exitWith {
    [false, STATUS_EXPENDED, format ["%1 has no squad to send", _callsign]]
};

if (_status isEqualTo STATUS_LAUNCHING) exitWith {[false, _status, format ["%1 is launching", _callsign]]};

if (_status isNotEqualTo STATUS_IDLE) exitWith {
    if (_kind isEqualTo KIND_TRANSPORT) exitWith {[true, _status, ""]};
    // ON STATION A CAS AIRCRAFT CAN BE MOVED: a new SAD or LOITER repositions
    // the orbit, the way Simplex's loiter takes a second confirm
    // (FUNC(casOrder)) - and a class aircraft on station takes a board's
    // ATTACK RUN from there (user, 2026-11-02).
    if (_status isEqualTo STATUS_ON_STATION) exitWith {[true, _status, ""]};
    [false, _status, format ["%1 is already on a task", _callsign]]
};

// Its airframe lost: the next one is made at the first tasking after the
// respawn delay (user, 2026-11-02).
if (CBA_missionTime < _respawnAt) exitWith {call _fnc_replacing};

private _readyAt = _logic getVariable [QGVAR(readyAt), 0];
if (CBA_missionTime < _readyAt) exitWith {
    [false, STATUS_COOLDOWN, format ["%1 is turning round - %2s", _callsign, ceil (_readyAt - CBA_missionTime)]]
};

[true, STATUS_IDLE, ""]
