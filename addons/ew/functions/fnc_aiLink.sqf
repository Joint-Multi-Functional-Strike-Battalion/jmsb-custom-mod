#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: THE COMMS GATE for one report (DESIGN_EW "Comms gate the AI"):
 * whether a fix reported from where the AI sensor stood reaches a group, and
 * how late. Inside AI_VOICE_M it is shouted - always, at once. Beyond, it
 * goes by radio: one hop of AI_HOP_S, and it gets through with the chance of
 * the link's quality - RF's own link budget (jmfsb_rf_fnc_linkBudget) for
 * the group's set (FUNC(aiSet)) at both ends, on its first band, over
 * RF's clear-ground path loss, against RF's noise at the group (so a
 * player's jammer on that band cuts the AI's reporting as it cuts a
 * player's), the set's spread gain taken off the jamming as a key holder's
 * is. A group with no set hears only by voice.
 *
 * One hop, clear ground: there are no AI RF nodes to mesh through and no
 * HQ node to route to (README "Not built").
 *
 * Arguments:
 * 0: Where the report comes from, ASL <ARRAY>
 * 1: The group it has to reach <GROUP>
 *
 * Return Value:
 * [chance 0..1, delay s] <ARRAY>
 *
 * Example:
 * ([_from, _group] call jmfsb_ew_fnc_aiLink) params ["_chance", "_delay"]
 *
 * Public: No
 */

params [["_from", [0, 0, 0], [[]], 3], ["_group", grpNull, [grpNull]]];

private _leader = leader _group;
if (isNull _leader) exitWith {[0, 0]};

private _to = eyePos _leader;
private _dist = _from distance2D _to;
if (_dist <= AI_VOICE_M) exitWith {[1, 0]};

([_group] call FUNC(aiSet)) params ["_man", "_profile"];
if (isNull _man) exitWith {[0, 0]};

private _prof = [_profile] call EFUNC(rf,profile);
private _band = (_prof getOrDefault ["bands", []]) param [0, ""];
if (_band isEqualTo "") exitWith {[0, 0]};

private _gain = _prof getOrDefault ["antennaGainDb", 0];
private _loss = [_dist, _band] call EFUNC(rf,pathLossFree);
private _noise = [_to, _band, "", _prof getOrDefault ["spreadGainDb", 0]] call EFUNC(rf,noise);
private _budget = [
    _prof getOrDefault ["txPowerDbm", 0], _gain, _gain, _loss, _noise,
    _prof getOrDefault ["rxSensDbm", EXPOSURE_SENS_DBM]
] call EFUNC(rf,linkBudget);

[_budget param [2, 0], AI_HOP_S]
