#include "script_component.hpp"
/*
 * Author: JMSB
 * TROOPS IN CONTACT - the send itself, with nothing drawn.
 *
 * LIFTED OUT OF FUNC(panelTic) SO THERE CAN BE A KEY. The whole send used to
 * live inside the map panel's hit handler, which meant the only way to raise a
 * TIC was to open the map and find the button - and a man being shot at is not
 * opening a map. There are two ways in now, and exactly one of them knows how
 * to file a contact report; the panel calls this, the keybind calls this, and
 * neither can drift from the other. Same reasoning as the EW gate in
 * EFUNC(messaging,submit): one door, one answer.
 *
 * IT SENDS A REPORT AND DOES NOTHING ELSE. Marking the map, alerting the side
 * and filing the thread on the command net all come off the template's own
 * broadcast flag on the server - see EFUNC(messaging,srvTic) - so a TIC fired
 * from a key is byte for byte a TIC filled in by hand.
 *
 * THE COOLDOWN IS THE POINT OF THIS BEING SHARED. A man under fire presses the
 * button more than once, and now he can also hold a key down. Without one stamp
 * that both paths read, the section files three contact reports, three markers
 * and three alerts for one contact. The engine's own nonce cannot help - each
 * press is a different draft.
 *
 * Arguments:
 * 0: Say why it was refused, in chat as well as the notification <BOOL>
 *    (optional, default true) - the panel draws its own refusal states, the
 *    keybind has no screen to draw them on.
 *
 * Return Value:
 * 0: Sent <BOOL>
 * 1: Why not, "" when sent <STRING>
 *
 * Example:
 * [] call jmfsb_tacpad_apps_fnc_ticSend;
 *
 * Public: Yes
 */

params [["_loud", true, [true]]];

private _fnc_no = {
    params ["_why"];
    if (_loud) then {
        ["TIC", _why, "high"] call EFUNC(messaging,notify);
        systemChat format ["[TIC] %1", _why];
    };
    [false, _why]
};

if (isNull player || {!alive player}) exitWith {["Not alive"] call _fnc_no};

// Nothing to send it TO. The panel says this on the cell before the press;
// from a key there is nowhere to say it but here.
private _nets = ((EGVAR(messaging,namedBoxes) splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};
if (isNil QEFUNC(messaging,submit) || {_nets isEqualTo []}) exitWith {
    ["No command net configured"] call _fnc_no
};

private _left = TIC_COOLDOWN - (CBA_missionTime - (missionNamespace getVariable [QGVAR(ticLast), -1e9]));
if (_left > 0) exitWith {
    [format ["Contact report already sent - %1s", ceil _left]] call _fnc_no
};

// THE LOCATION IS HIS GPS FIX (jmfsb_ew_fnc_gpsHere, when EW is loaded): the
// false one when spoofed; denied, there is nothing to send it with, and the
// card - where a grid is typed - is the way.
private _at = if (isNil QEFUNC(ew,gpsHere)) then {getPosATL player} else {[] call EFUNC(ew,gpsHere)};
if (_at isEqualTo []) exitWith {
    ["No GPS fix - send the TIC from the card with your grid"] call _fnc_no
};

// The deck's own report, with the two required lines answered from what the
// game knows. ENEMY is what a man would say into a radio before he has looked
// properly, and it is the line the follow-up card exists to replace.
([
    "tic",
    [
        ["Location.A", _at],
        ["Enemy.A", "CONTACT - DETAILS TO FOLLOW"],
        ["Intentions.A", "Returning fire"]
    ],
    [format ["B:%1", _nets # 0]]
] call EFUNC(messaging,submit)) params ["_ok", "_why"];

if (!_ok) exitWith {[_why] call _fnc_no};

GVAR(ticLast) = CBA_missionTime;

// The map panel counts the hold down on a two-second tick, so it repaints
// itself when it is the one that sent. A key press with the map shut has no
// panel to rebuild and the rebuild is a no-op, which is why it is not guarded.
{["tic"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;

[true, ""]
