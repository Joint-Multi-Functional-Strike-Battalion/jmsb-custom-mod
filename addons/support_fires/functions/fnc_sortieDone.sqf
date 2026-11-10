#include "script_component.hpp"
/*
 * Author: YonV
 * One missile or munition of a launch is gone - on target, shot down,
 * self-destructed or never launched. The last one ends the mission - or, for
 * a call for fire by message (FUNC(threadStrike), 2026-11-01), puts the
 * launcher on hold (STATUS_HOLDING) and asks ROUNDS COMPLETE - REQUEST BDA
 * (unobserved: END OF MISSION?) in its thread, with the D9 waits
 * (FUNC(threadPrompt)). The observer's answer ends or repeats it.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The mission's token <NUMBER>
 * 2: What the asset says about this one, "" for nothing <STRING> (optional, default "")
 *
 * Return Value: None
 *
 * Example:
 * [_logic, 3, "missile lost"] call jmfsb_support_fires_fnc_sortieDone
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_token", -1, [0]], ["_said", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};
if (_token isNotEqualTo (_logic getVariable [QGVAR(token), -1])) exitWith {};

if (_said isNotEqualTo "") then {
    [_logic, _said, "normal"] call FUNC(say);
};

private _left = (_logic getVariable [QGVAR(inFlight), 1]) - 1;
_logic setVariable [QGVAR(inFlight), _left];

if (_left > 0) exitWith {};
if ((_logic getVariable [QGVAR(thread), ""]) isEqualTo "") exitWith {
    [_logic, _token, "mission complete"] call FUNC(finish);
};

// A CALL FOR FIRE'S LAUNCH (2026-11-01) holds for the observer instead, its
// thread open and the target marked, and asks for the BDA as a battery does.
_logic setVariable [QGVAR(status), STATUS_HOLDING, true];
[_logic, SAID_COMPLETE, "normal"] call FUNC(say);
// ROUNDS COMPLETE (2026-11-09): the card in the thread, then the question.
[format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _logic getVariable [QGVAR(thread), ""], CARD_ROUNDS_COMPLETE, [], _logic getVariable [QGVAR(callsign), ""]] call EFUNC(support,fileCard);
if ((_logic getVariable [QGVAR(threadOrder), createHashMap]) getOrDefault ["observed", true]) exitWith {
    [_logic, PROMPT_COMPLETE, ANSWERS_COMPLETE] call FUNC(threadPrompt);
};
[_logic, PROMPT_UNOBSERVED, ANSWERS_EOM] call FUNC(threadPrompt);
