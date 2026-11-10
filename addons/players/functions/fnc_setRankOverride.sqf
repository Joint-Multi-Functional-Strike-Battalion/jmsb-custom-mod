#include "script_component.hpp"
/*
    File: fn_player_setRankOverride.sqf
    Author: YonV
    Description: (Server) Sets a player's rank in the live Steam-ID rank map
        (YMF_playerRanks) and applies the engine rank on the target. Rank changes made
        here immediately drive role access (see fn_canTakeRole). This is a SESSION change
        - config\config_ranks.hpp stays the source of truth. Every change appends to a
        running promotion list and dumps a paste-ready block of Steam IDs (grouped by
        rank) to the RPT so an admin can update Dynamic_Ranks in config_ranks.hpp.

    Arguments:
    0: Steam UID <STRING>
    1: Rank <STRING> - one of Private/Corporal/Sergeant/Lieutenant/Captain/Major/Colonel
    2: Unit <OBJECT> (Optional) - the target unit, to apply the engine rank
    3: Admin name <STRING> (Optional) - for the RPT audit line

    Example:
    [getPlayerUID _t, "Sergeant", _t, name player] remoteExecCall ["jmfsb_players_fnc_setRankOverride",2];
*/

params [
    ["_uid", "", [""]],
    ["_rank", "", [""]],
    ["_unit", objNull, [objNull]],
    ["_adminName", "", [""]]
];

if (!isServer) exitWith {};
if (_uid isEqualTo "") exitWith {};
// Only an admin by the server's records may set a rank (review S4); the admin's
// name for the log is the sender's own, not the one he passed.
if !([] call EFUNC(common,senderIsAdmin)) exitWith {
    WARNING_2("Players","setRankOverride refused for %1: machine %2 is not an admin",_uid,remoteExecutedOwner);
};
private _sender = ([] call EFUNC(common,sender)) select 1;
if (!isNull _sender) then {_adminName = name _sender};

private _order = ["PRIVATE","CORPORAL","SERGEANT","LIEUTENANT","CAPTAIN","MAJOR","COLONEL"];
private _idx = _order find toUpper _rank;
if (_idx isEqualTo -1) exitWith {diag_log format ["[YMF][RANK] Rejected invalid rank '%1' for %2", _rank, _uid];};

// normalise to the proper-case name used in config_ranks.hpp
private _rankProper = ["Private","Corporal","Sergeant","Lieutenant","Captain","Major","Colonel"] select _idx;

// live update - getRank/canTakeRole read this map, so role access updates immediately.
// Nothing in the mod creates the map; a mission may (review B13).
if (isNil "YMF_playerRanks") then {YMF_playerRanks = createHashMap};
YMF_playerRanks set [_uid, _rankProper];
publicVariable "YMF_playerRanks";

// track promotions made this session
if (isNil "YMF_rankPromotions") then {YMF_rankPromotions = createHashMap};
YMF_rankPromotions set [_uid, _rankProper];

// apply the engine rank (rank icon) on the target's machine
if (!isNull _unit) then {
    [_unit, "BIS"] remoteExecCall [QUOTE(EFUNC(players,setRank)), _unit];
};

diag_log format ["[YMF][RANK] %1 set %2 (%3) to %4", _adminName, name _unit, _uid, _rankProper];

// dump a config-ready block: promoted Steam IDs grouped by rank
private _byRank = createHashMap;
{
    private _r = YMF_rankPromotions get _x;
    (_byRank getOrDefault [_r, [], true]) pushBack _x;
} forEach keys YMF_rankPromotions;

diag_log "===== YMF RANK PROMOTIONS (paste into config_ranks.hpp >> Dynamic_Ranks) =====";
{
    private _ids = _byRank get _x;
    diag_log format ["	class %1 {", _x];
    diag_log "		uids[] = {";
    {
        private _sep = [",",""] select (_forEachIndex >= (count _ids) - 1);
        diag_log format ["			""%1""%2", _x, _sep];
    } forEach _ids;
    diag_log "		};";
    diag_log "	};";
} forEach keys _byRank;
diag_log "===== END RANK PROMOTIONS =====";
