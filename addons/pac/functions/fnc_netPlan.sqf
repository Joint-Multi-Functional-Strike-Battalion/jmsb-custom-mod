#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_netPlan

Description:
    THE RADIO PLAN AS NETS. Voice is game VoIP (docs/DESIGN_VOICE.md, D14):
    nothing is tuned, so the plan names nets, not frequencies. A plan row is
    [net name, short range slot, long range slot] under the key that has
    always held it (jmfsbFR_radio_tfarNets - the name is kept so a saved plan
    still reads). A row names a short range net on its slot; long range slots
    are shared between rows, so a long range net is named by its slot number.
    The plan's fallback slots are nets too, named by number when no row names
    them. Every voice net is VHF.

    The same on every machine, since the plan is on every machine: the server
    makes the nets in RF (FUNC(netPlanSync)); jmfsb_voice reads the same list
    for membership.

    THE VON PLAN WINS when it has nets (2026-10-20: jmfsbFR_radio_vonNets,
    the keys DIVINER and the website write). Then the plan is: a TEAM net
    (kind "sr") per squad - its jmfsbFR_radio_vonTeamNets name, else the
    squad's own - for every ORBAT squad and every squad the VON rows name; a
    "lr" net per c2 row and an "a2g" net per a2g row, by the row's name. VON
    nets are named, not slotted, so their slot is NET_NO_SLOT: membership is
    by squad (FUNC(netPlanSquad)), and a reader that looks a squad up by slot
    finds nothing there and keeps its own default. A name already taken by an
    earlier net is skipped. With no vonNets rows the plan is the tfarNets one,
    exactly as before.

Parameters:
    None

Returns:
    [[net id, band, "sr" | "lr" | "a2g", slot (0-based, NET_NO_SLOT for a
    VON net)], ...] <ARRAY>

Example:
    [] call jmfsb_pac_fnc_netPlan

Author:
    JMSB
---------------------------------------------------------------------------- */

private _von = missionNamespace getVariable ["jmfsbFR_radio_vonNets", []];
if !(_von isEqualType []) then {_von = []};
_von = _von select {_x isEqualType [] && {(_x param [0, ""]) isEqualType ""} && {trim (_x param [0, ""]) isNotEqualTo ""}};

if (_von isNotEqualTo []) exitWith {
    if (count _von > VON_MAX_NETS) then {_von resize VON_MAX_NETS};
    private _vonOut = [];
    private _taken = [];

    // the squads: the ORBAT's, then any a VON row names that the ORBAT does not
    private _squads = [];
    if (!isNil "jmfsb_groups_fnc_orbat") then {
        {_squads pushBackUnique toUpper (_x param [0, ""])} forEach (([] call jmfsb_groups_fnc_orbat) param [0, []]);
    };
    {
        {
            if (_x isEqualType "") then {_squads pushBackUnique toUpper trim _x};
        } forEach (_x param [2, [], [[]]]);
    } forEach _von;
    _squads = _squads - [""];

    {
        private _team = toUpper ([_x, NET_KIND_SR] call FUNC(netPlanSquad));
        if (_team isNotEqualTo "" && !(_team in _taken)) then {
            _taken pushBack _team;
            _vonOut pushBack [_team, NET_VOICE_BAND, NET_KIND_SR, NET_NO_SLOT];
        };
    } forEach _squads;

    {
        private _name = toUpper trim (_x # 0);
        private _kind = [NET_KIND_LR, NET_KIND_A2G] select ((toLower (_x param [1, "", [""]])) isEqualTo VON_KIND_A2G);
        if !(_name in _taken) then {
            _taken pushBack _name;
            _vonOut pushBack [_name, NET_VOICE_BAND, _kind, NET_NO_SLOT];
        };
    } forEach _von;

    _vonOut
};

private _out = [];
private _srTaken = [];
private _lrTaken = [];
{
    if !(_x isEqualType []) then {continue};
    _x params [["_name", "", [""]], ["_sr", NET_NO_SLOT, [0]], ["_lr", NET_NO_SLOT, [0]]];
    if (_name isNotEqualTo "" && _sr > NET_NO_SLOT && !(_sr in _srTaken)) then {
        _srTaken pushBack _sr;
        _out pushBack [toUpper _name, NET_VOICE_BAND, NET_KIND_SR, _sr];
    };
    if (_lr > NET_NO_SLOT && !(_lr in _lrTaken)) then {
        _lrTaken pushBack _lr;
        _out pushBack [format [NET_LR_FORMAT, _lr + 1], NET_VOICE_BAND, NET_KIND_LR, _lr];
    };
} forEach (missionNamespace getVariable ["jmfsbFR_radio_tfarNets", []]);

private _srFallback = missionNamespace getVariable ["jmfsbFR_radio_tfarSwFallback", NET_NO_SLOT];
if (_srFallback isEqualType 0 && {_srFallback > NET_NO_SLOT && !(_srFallback in _srTaken)}) then {
    _out pushBack [format [NET_SR_FORMAT, _srFallback + 1], NET_VOICE_BAND, NET_KIND_SR, _srFallback];
};
private _lrFallback = missionNamespace getVariable ["jmfsbFR_radio_tfarLrFallback", NET_NO_SLOT];
if (_lrFallback isEqualType 0 && {_lrFallback > NET_NO_SLOT && !(_lrFallback in _lrTaken)}) then {
    _out pushBack [format [NET_LR_FORMAT, _lrFallback + 1], NET_VOICE_BAND, NET_KIND_LR, _lrFallback];
};

_out
