#include "script_component.hpp"
/*
 * Author: YonV
 * A man died. Decide, once, whether his body is worth searching.
 *
 * WHAT A BODY YIELDS DEPENDS ON WHOSE WAR HE WAS FIGHTING, and that comes
 * from his commander's controltype rather than from a list of factions here:
 *
 *   asymmetric commander's side  - his PHONE. The phone is the insurgency's
 *                                  paperwork, so every insurgent has one.
 *   occupation / invasion side   - his RADIO, when he is actually carrying
 *                                  one. A conventional soldier's set is the
 *                                  same prize by another name: nets, call
 *                                  signs, frequencies.
 *   anyone else                  - the documents roll.
 *
 * Decided at death rather than at search time, so two players searching the
 * same corpse cannot get two different answers.
 *
 * WHERE THE MAN WAS LOCAL, DECIDED ON THE SERVER (review B20). Killed fires
 * only on the machine that owns the man, and it was registered on the server
 * alone - AI on a headless client never dropped intel. The class handler is on
 * every machine now; a machine that is not the server sends the death here by
 * remoteExec, and the server takes it only from the machine that owned him
 * (review S7), only for a dead man, and only once.
 *
 * Arguments:
 * 0: The body <OBJECT>
 * 1: His side, as his own machine saw it - read only when his group is
 *    already gone on the server (optional) <SIDE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body] call jmfsb_hacking_fnc_onBodyKilled
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_sideSent", sideUnknown, [sideUnknown]]];

if (isNull _unit || {isPlayer _unit}) exitWith {};
if (!isServer) exitWith {
    if (local _unit) then {
        [_unit, side group _unit] remoteExecCall [QFUNC(onBodyKilled), SERVER_OWNER];
    };
};
if (alive _unit || {!([_unit] call EFUNC(common,senderIs))}) exitWith {};
if (_unit getVariable [QGVAR(bodyDecided), false]) exitWith {};
_unit setVariable [QGVAR(bodyDecided), true];

private _side = [side group _unit, _sideSent] select (isNull group _unit);
if (_side isEqualTo civilian) exitWith {};

// Cached at adapter-ready: side text -> controltype. Commanders do not change
// mid-mission, and this runs on every death.
private _type = GVAR(sideControl) getOrDefault [str _side, ""];

private _has = switch (_type) do {
    case "asymmetric": { [_unit] call FUNC(hasPhone) };
    case "occupation";
    case "invasion":   { [_unit] call FUNC(hasRadio) };
    default            { random 100 < GVAR(docChance) };
};

if (_has) then {
    _unit setVariable [QGVAR(bodyIntel), true, true];
};
