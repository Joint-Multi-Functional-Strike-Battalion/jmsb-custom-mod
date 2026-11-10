#include "script_component.hpp"
/*
 * Author: YonV
 * How one asset reads in the TO picker's SUPPORT group: its call sign, and
 * one line of type, state and ETA (docs/DESIGN_SUPPORT_MESSAGING.md section 3,
 * the contact row):
 *
 *   HOG          CAS - IDLE - ETA 2:40
 *   RAVEN        CAS - REARMING - COOLDOWN 40 S
 *   J. SMITH     CAS - PLAYER - AH-64D APACHE
 *   THUNDER      ARTY - IDLE - 12 HE, 6 SMOKE - ETA 1:20
 *
 * A BATTERY'S STOCK (user, 2026-11-02) rides in the row's field 9, where a
 * player crew's vehicle does (EFUNC(support,mailboxes)).
 *
 * A PLAYER CREW (decision D8, user 2026-11-01) reads PLAYER and the vehicle
 * he crews - no state or ETA from a provider; nothing acts on his box.
 *
 * A ROW THAT CANNOT TAKE A TASK IS DIM AND SAYS WHY - the reason after the
 * state, unless it only says the state again. An ETA nobody can give (-1) is
 * not shown. The same answer for the full draw (FUNC(composeToSupportDraw))
 * and the poll's in-place update (FUNC(composeToSupportTick)), so the two
 * never read differently.
 *
 * Arguments:
 * 0: Row, as EFUNC(support,mailboxes) gives it <ARRAY>
 * 1: It is the address now - drawn on the accent <BOOL>
 *
 * Return Value:
 * 0: The call sign, [text, RGBA] <ARRAY>
 * 1: Type, state and ETA, [text, RGBA] <ARRAY>
 *
 * Example:
 * ([_row, false] call jmfsb_tacpad_fnc_composeToSupportLine) params ["_name", "_meta"]
 *
 * Public: No
 */

params [["_row", [], [[]]], ["_on", false, [false]]];

_row params ["", ["_callsign", "", [""]], "", ["_word", "", [""]], ["_state", "", [""]], ["_can", false, [false]], ["_why", "", [""]], ["_eta", -1, [0]], "", ["_vehicle", "", [""]]];

([] call FUNC(theme)) params ["_ground", "_ink"];
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

private _parts = [_word, _state];
if (!_can && _why isNotEqualTo "" && _why isNotEqualTo _state) then {
    _parts pushBack _why;
};
// A player crew (decision D8, 2026-11-01): PLAYER, and what he crews.
_parts pushBack _vehicle;
if (_eta >= 0) then {
    private _s = ceil _eta;
    _parts pushBack format ["ETA %1:%2", floor (_s / TO_SECS_PER_MIN), [_s mod TO_SECS_PER_MIN, 2] call CBA_fnc_formatNumber];
};

[
    [_callsign, [[_dim, _ink] select _can, _ground] select _on],
    [(_parts select {_x isNotEqualTo ""}) joinString TO_SUPPORT_SEP, [[_dim, _muted] select _can, _ground] select _on]
]
