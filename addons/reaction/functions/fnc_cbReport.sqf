#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the counter-battery radar's report of enemy artillery to the
 * players' artillery teams (user, 2026-10-25: "the arty notification for enemy
 * arty fire so the team can counter-battery it can just be a message in the
 * messaging system ... no new notification system"). Every player side
 * hostile to the firing side that has an artillery team (jmfsb_common_fnc_
 * artyGroups - the ORBAT squad kind art or mortar) gets a TAC//MSG thread from
 * CB RADAR to that team, pinned on the map at the fix, and the fix itself for
 * the team's ARTY tile and calculator. The fix is off true by up to
 * cbRadarError metres.
 *
 * Arguments:
 * 0: Where the guns are, ATL <ARRAY>
 * 1: The firing side <SIDE>
 * 2: What fired, for the message <STRING>
 *
 * Return Value:
 * Teams told <NUMBER>
 *
 * Example:
 * [_pos, east, "2S9 Sochor"] call jmfsb_reaction_fnc_cbReport
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_gside", sideUnknown, [sideUnknown]], ["_what", "", [""]]];

if (!isServer || {_pos isEqualTo []} || {isNil QEFUNC(messaging,srvSubmit)}) exitWith {0};
if (_what isEqualTo "") then {_what = CB_WHAT_DEFAULT};

private _fix = _pos getPos [random GVAR(cbRadarError), random 360];
private _key = ((["freetext"] call EFUNC(messaging,template)) getOrDefault ["order", []]) param [0, "Text.A"];
date params ["", "", "", "_h", "_m"];
private _sides = allPlayers apply {side group _x};

private _told = 0;
{
    private _pside = _x;
    if (_pside getFriend _gside >= 0.6) then {continue};
    {
        private _carrier = (units _x) select {isPlayer _x && {alive _x}};
        if (_carrier isEqualTo []) then {continue};
        private _text = format [
            "COUNTER-BATTERY RADAR: enemy %1 firing from grid %2 (within %3 m) at %4:%5. Counter-battery when ready. Over.",
            _what, mapGridPosition _fix, round GVAR(cbRadarError),
            [_h, 2] call CBA_fnc_formatNumber, [_m, 2] call CBA_fnc_formatNumber
        ];
        [
            _carrier select 0, format ["cbradar:%1:%2", diag_frameNo, floor random 1e6], "freetext",
            [[_key, _text]], [format ["G:%1", groupId _x]], "", "", CB_RADAR_CALLSIGN, [], _fix
        ] call EFUNC(messaging,srvSubmit);
        // The fix itself, for the team's ARTY tile and calculator (no popup -
        // the message is the notice).
        [QGVAR(cbFix), [_fix, CBA_missionTime, _what], _carrier] call CBA_fnc_targetEvent;
        _told = _told + 1;
    } forEach ([_pside] call EFUNC(common,artyGroups));
} forEach (_sides arrayIntersect _sides);

if (_told > 0) then {
    INFO_3("counter-battery radar: %1 at %2 reported to %3 team(s)",_what,mapGridPosition _fix,_told);
};
_told
