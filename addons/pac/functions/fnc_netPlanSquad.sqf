#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_netPlanSquad

Description:
    A squad's net of the plan (FUNC(netPlan)), by kind: "sr" is its TEAM
    net, "lr" its C2-kind net, "a2g" its air-to-ground net.

    THE VON PLAN (jmfsbFR_radio_vonNets has rows): the TEAM net is the
    squad's jmfsbFR_radio_vonTeamNets name, else the squad's own name; the
    lr net is the FIRST c2 row that lists the squad - the website warns
    about, but allows, a squad on two c2 nets, and the first is its long
    range net; the a2g net is likewise the first a2g row that lists it.

    THE tfarNets PLAN (no VON rows): the squad's row gives the slot (else
    the plan's fallback slot) and the net is the plan net on that slot -
    what jmfsb_voice_fnc_planNet does for a unit.

Parameters:
    0: Squad name <STRING>
    1: Kind "sr" | "lr" | "a2g" <STRING> (optional, default "sr")

Returns:
    Net id, "" when the plan has none for the squad <STRING>

Example:
    ["ALPHA", "lr"] call jmfsb_pac_fnc_netPlanSquad

Author:
    JMSB
---------------------------------------------------------------------------- */

params [["_squad", "", [""]], ["_kind", NET_KIND_SR, [""]]];

_squad = toUpper trim _squad;
if (_squad isEqualTo "") exitWith {""};

private _von = missionNamespace getVariable ["jmfsbFR_radio_vonNets", []];
if !(_von isEqualType []) then {_von = []};
_von = _von select {_x isEqualType [] && {(_x param [0, ""]) isEqualType ""} && {trim (_x param [0, ""]) isNotEqualTo ""}};

if (_von isNotEqualTo []) exitWith {
    if (_kind isEqualTo NET_KIND_SR) exitWith {
        private _rows = missionNamespace getVariable ["jmfsbFR_radio_vonTeamNets", []];
        if !(_rows isEqualType []) then {_rows = []};
        private _at = _rows findIf {
            _x isEqualType [] && {(_x param [0, ""]) isEqualType ""} && {toUpper trim (_x param [0, ""]) isEqualTo _squad}
        };
        private _team = if (_at < 0) then {""} else {(_rows # _at) param [1, ""]};
        if (!(_team isEqualType "") || {trim _team isEqualTo ""}) exitWith {_squad};
        toUpper trim _team
    };
    if (count _von > VON_MAX_NETS) then {_von resize VON_MAX_NETS};
    private _want = [VON_KIND_C2, VON_KIND_A2G] select (_kind isEqualTo NET_KIND_A2G);
    // the FIRST row of the kind that lists the squad
    private _at = _von findIf {
        (toLower (_x param [1, "", [""]])) isEqualTo _want
        && {_squad in ((_x param [2, [], [[]]]) apply {if (_x isEqualType "") then {toUpper trim _x} else {""}})}
    };
    if (_at < 0) exitWith {""};
    toUpper trim ((_von # _at) # 0)
};

// the tfarNets plan: slot by the squad's row, else the fallback slot
if (_kind isEqualTo NET_KIND_A2G) exitWith {""};
private _sr = _kind isEqualTo NET_KIND_SR;
private _rows = missionNamespace getVariable ["jmfsbFR_radio_tfarNets", []];
if !(_rows isEqualType []) then {_rows = []};
private _at = _rows findIf {_x isEqualType [] && {(_x param [0, ""]) isEqualType ""} && {toUpper (_x param [0, ""]) isEqualTo _squad}};
private _slot = if (_at >= 0) then {
    (_rows # _at) param [[NET_COL_LR, NET_COL_SR] select _sr, NET_NO_SLOT]
} else {
    missionNamespace getVariable [["jmfsbFR_radio_tfarLrFallback", "jmfsbFR_radio_tfarSwFallback"] select _sr, NET_NO_SLOT]
};
if (!(_slot isEqualType 0) || {_slot <= NET_NO_SLOT}) exitWith {""};

private _setKind = [NET_KIND_LR, NET_KIND_SR] select _sr;
private _net = ([] call FUNC(netPlan)) select {(_x # 2) isEqualTo _setKind && {(_x # 3) isEqualTo _slot}};
if (_net isEqualTo []) exitWith {""};
(_net # 0) # 0
