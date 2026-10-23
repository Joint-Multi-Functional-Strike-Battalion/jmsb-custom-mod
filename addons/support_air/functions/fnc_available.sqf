#include "script_component.hpp"
/*
 * Author: JMSB
 * What this asset is doing, as one token, and whether it can take an order -
 * the ONE answer the row, the "available" code and the order all read, so a
 * row that reads idle is never refused.
 *
 * A TRANSPORT IS RE-TASKABLE WHILE IT IS OUT. A helicopter sitting at the LZ
 * waiting for the next order is the normal case, and a row that refused it
 * because it read WAITING would make the second order impossible. Its row
 * still shows what it is doing (not "idle"), so RTB stays armed.
 *
 * SPENT IS A STATE, NOT A DISAPPEARANCE. A module out of sorties, drops,
 * squads or airframes stays on the page and says EXPENDED.
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

// GONE FOR GOOD: Respawn Delay -1, or the last airframe a transport had.
if (_logic getVariable [QGVAR(dead), false]) exitWith {[false, STATUS_EXPENDED, format ["%1 has lost its aircraft", _callsign]]};

// A synced aircraft is the asset: while it is a wreck, the asset waits for
// its replacement (FUNC(respawn)) - or is gone, when there will be none.
private _respawnAt = _logic getVariable [QGVAR(respawnAt), 0];
private _fnc_replacing = {
    private _left = ceil (_respawnAt - CBA_missionTime);
    [false, STATUS_REPLACING, [format ["%1 is waiting for a replacement aircraft", _callsign], format ["%1 has a replacement aircraft in %2s", _callsign, _left]] select (_left > 0)]
};
if (_hadSynced && {!alive _synced}) exitWith {
    if ((_logic getVariable [QGVAR(respawnDelay), RESPAWN_NEVER]) < 0) exitWith {[false, STATUS_EXPENDED, format ["%1 has lost its aircraft", _callsign]]};
    call _fnc_replacing
};

if ((_logic getVariable [QGVAR(left), -1]) isEqualTo 0 && _status isEqualTo STATUS_IDLE) exitWith {
    [false, STATUS_EXPENDED, format ["%1 is spent", _callsign]]
};

private _airframes = _logic getVariable [QGVAR(airframes), 0];
if (_airframes > 0 && {(_logic getVariable [QGVAR(lost), 0]) >= _airframes}) exitWith {
    [false, STATUS_EXPENDED, format ["%1 has no airframes left", _callsign]]
};

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
    // (FUNC(casOrder)).
    if (_kind isEqualTo KIND_CAS && _status isEqualTo "on station") exitWith {[true, _status, ""]};
    [false, _status, format ["%1 is already on a task", _callsign]]
};

// A class aircraft lost: the next one is ready when the respawn delay is up.
if (CBA_missionTime < _respawnAt) exitWith {call _fnc_replacing};

private _readyAt = _logic getVariable [QGVAR(readyAt), 0];
if (CBA_missionTime < _readyAt) exitWith {
    [false, STATUS_COOLDOWN, format ["%1 is turning round - %2s", _callsign, ceil (_readyAt - CBA_missionTime)]]
};

[true, STATUS_IDLE, ""]
