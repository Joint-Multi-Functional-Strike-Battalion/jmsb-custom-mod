#include "script_component.hpp"
/*
 * Author: YonV
 * The medical profile's alerts (design medical.alerts), asked once a second
 * by the watch for each patient; a new one goes through the notification row:
 *
 *     T1              the card, or the suggestion while no card is set
 *     TQ OVER 10 MIN  a tourniquet on longer than TQ_ALERT seconds
 *     SPO2 UNDER 90   below SPO2_ALERT
 *     MIST STALE      a MIST was opened on him, and the triage changed since
 *                     or it is older than MIST_STALE seconds
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * The alerts that hold now <ARRAY>
 *
 * Example:
 * [_unit] call jmfsb_medic_fnc_watchAlerts
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!alive _unit) exitWith {[]};
private _out = [];
private _card = _unit getVariable [ACEV_TRIAGE, 0];
if (_card isEqualTo 1 || {_card < 1 && {([_unit] call FUNC(triageSuggest)) isEqualTo 1}}) then {_out pushBack "T1"};
if ((_unit getVariable [ACEV_TOURNIQUETS, []]) findIf {if (_x isEqualType 0) then {_x > 0 && (CBA_missionTime - _x) > TQ_ALERT} else {false}} >= 0) then {
    _out pushBack "TQ OVER 10 MIN";
};
if ((_unit getVariable [ACEV_SPO2, SPO2_FULL]) < SPO2_ALERT) then {_out pushBack "SPO2 UNDER 90"};
(GVAR(mistSent) getOrDefault [hashValue _unit, []]) params [["_sent", -1], ["_triage", 0]];
if (_sent >= 0 && {_triage isNotEqualTo _card || {(CBA_missionTime - _sent) > MIST_STALE}}) then {_out pushBack "MIST STALE"};
_out
