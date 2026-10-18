#include "script_component.hpp"
/*
 * Author: JMSB
 * The net card under a friendly player's box - only for a man ON THE NET, a
 * player of your faction or side whose radio is published (user, 2026-10-17:
 * "if they are on net give player health call sign radio freq and ace ... and
 * squad and roles"):
 *
 *   SGT Reyes | MED                      rank, name (his callsign) and role
 *   OVERLORD 6 1                         his squad
 *   WIA 64% | CH 3 - GHOST | 43.100      health, channel, frequency
 *   ACE  A C E                           his ACE report, each letter coloured
 *
 * Everything is what the TAC//PAD squad page already reads - the channel and
 * ACE report each man publishes, its role and rank names, its health test - so
 * the card and the squad table never disagree. The frequency is ECOTI's own
 * (FUNC(publishFreq)). Settled twice a second, not per frame.
 *
 * Arguments:
 * 0: Target <OBJECT>
 *
 * Return Value:
 * [structured text lines after the first, line count] - ["", 0] when he is not on the net <ARRAY>
 *
 * Example:
 * [_unit] call jmfsb_ecoti_fnc_targetCard
 *
 * Public: No
 */

params [["_target", objNull, [objNull]]];

if !(_target isKindOf "CAManBase" && {isPlayer _target}) exitWith {["", 0]};
if !((_target getVariable [QGVAR(rgb), []]) in [GVAR(colorPlayer), GVAR(colorFriendly)]) exitWith {["", 0]};

private _channel = _target getVariable [QEGVAR(tacpad_apps,radio), ""];
if (_channel isEqualTo "") exitWith {["", 0]};

// Who: rank, name, role - the squad page's own short names when it is loaded.
private _rank = if (isNil QEFUNC(tacpad,rankShort)) then {rank _target} else {[rank _target] call EFUNC(tacpad,rankShort)};
private _role = if (isNil QEFUNC(tacpad,roleShort)) then {""} else {[_target] call EFUNC(tacpad,roleShort)};
private _who = format ["%1 %2", _rank, name _target];
if (_role isNotEqualTo "") then {_who = format ["%1%2%3", _who, LABEL_SEPARATOR, _role]};

// Health, the squad page's test.
private _out = if (isNil QEFUNC(common,isUnconscious)) then {
    lifeState _target == "INCAPACITATED"
} else {
    [_target] call EFUNC(common,isUnconscious)
};
private _health = round ((1 - damage _target) * 100);
private _status = switch (true) do {
    case (!alive _target): {"KIA"};
    case (_out): {"UNCON"};
    case (_health < CARD_HURT_BELOW): {format ["WIA %1%2", _health, "%"]};
    default {"EFFECTIVE"};
};

private _radio = _channel;
private _freq = _target getVariable [QGVAR(freq), ""];
if (_freq isNotEqualTo "") then {_radio = format ["%1%2%3", _radio, LABEL_SEPARATOR, _freq]};

// ACE - ammunition, casualty, equipment, as the man last reported them, the
// casualty letter overwritten by what the engine knows (dead, unconscious).
private _reported = _target getVariable [QEGVAR(tacpad_apps,ace), []];
private _casualty = switch (true) do {
    case (!alive _target): {3};
    case (_out): {2};
    default {_reported param [1, -1]};
};
private _ace = "ACE ";
{
    private _index = [_reported param [0, -1], _casualty, _reported param [2, -1]] select _forEachIndex;
    _ace = _ace + format [" <t color='%1'>%2</t>", ACE_COLOURS select ((_index max -1) + 1), _x];
} forEach ["A", "C", "E"];

private _lines = [_who, groupId (group _target), format ["%1%2%3", _status, LABEL_SEPARATOR, _radio]];
[((_lines apply {format ["<br/>%1", _x]}) joinString "") + "<br/>" + _ace, count _lines + 1]
