#include "script_component.hpp"
/*
 * Author: JMSB
 * Tells the players something a jmfsb system just did to them.
 *
 * THE PROBLEM THIS SOLVES. The drone fleet, the ambient artillery, the kamikaze
 * flights, the counter-battery radar, the strike aircraft, the EW net - all of
 * them are running, and none of them tell anybody anything. A mortar mission
 * walks onto a position and the first the section knows is a casualty; a recon
 * drone fixes them and the first they know is the drone that follows it. A
 * system the player cannot perceive is indistinguishable from bad luck, and bad
 * luck is not gameplay.
 *
 * So: one bus. A system posts what it is about to do and who it concerns, and
 * every device draws from the same place - see FUNC(onAlert).
 * The alternative is each addon growing its own notification, its own radius
 * test and its own opinion about what red means.
 *
 * WHO IS TOLD is worked out here rather than by the caller, because "everyone
 * within the danger area" is the same question every time and getting it wrong
 * means either spoiling the map or warning nobody.
 *
 * Arguments:
 * 0: Source, short and upper case - "ARTY", "FPV", "CB RADAR" <STRING>
 * 1: What happened, one short line <STRING>
 * 2: Where <ARRAY> (position AGL, [] for "no particular place")
 * 3: Who it concerns - metres from that position, 0 for everyone <NUMBER>
 * 4: Severity: 0 note, 1 caution, 2 danger <NUMBER> (optional, default 1)
 * 5: Seconds it stays on the device <NUMBER> (optional, default 120)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ARTY", "Fire mission inbound", _pos, 400, 2] call jmfsb_common_fnc_alert
 */

if (!isServer) exitWith {};

params [
    ["_source", "", [""]],
    ["_text", "", [""]],
    ["_pos", [], [[]]],
    ["_radius", 0, [0]],
    ["_severity", 1, [0]],
    ["_life", 120, [0]]
];

if (_source == "" || _text == "") exitWith {};

private _who = allPlayers select {alive _x};
if (_radius > 0 && {_pos isNotEqualTo []}) then {
    _who = _who select {(getPosATL _x) distance2D _pos <= _radius};
};
if (_who isEqualTo []) exitWith {};

// Grid rather than a marker: this is a warning, not intelligence. A marker
// would hand the player a solved problem; a grid makes them read a map.
private _grid = if (_pos isEqualTo []) then {""} else {mapGridPosition _pos};

// By remoteExec to FUNC(onAlert), which takes it only from the server or from
// its own machine - not a CBA event any client could raise (review S7).
[_source, _text, _grid, _severity, _life] remoteExecCall [QFUNC(onAlert), _who];
