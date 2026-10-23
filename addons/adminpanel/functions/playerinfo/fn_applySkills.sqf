/*
    Author: TheTimidShade
    Description:
        Gives the selected player skills for THIS mission only
    Parameters:
        NONE
    Returns:
        NONE
*/
#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

disableSerialization;

private _admp_display = uiNamespace getVariable ['admp_displayVar', displayNull];
if (isNull _admp_display) exitWith {}; // check display exists

private _admp_playerlist_listbox = _admp_display displayCtrl IDC_ADMINPANEL_PLAYERLIST_LISTBOX;
private _player = [_admp_playerlist_listbox] call admp_fnc_playerFromSelection; // get selected player
if (isNull _player) exitWith {["Admin Panel", "No target found!", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";}; // if there is no selected target exit

private _ticked = {cbChecked (_admp_display displayCtrl _this)};
private _clsSkill = IDC_ADMINPANEL_PLAYER_SKILLS_CLS_CHECKBOX call _ticked;
private _medSkill = IDC_ADMINPANEL_PLAYER_SKILLS_MED_CHECKBOX call _ticked;
private _engSkill = IDC_ADMINPANEL_PLAYER_SKILLS_ENG_CHECKBOX call _ticked;
private _brcSkill = IDC_ADMINPANEL_PLAYER_SKILLS_EOD_CHECKBOX call _ticked;
private _isrSkill = IDC_ADMINPANEL_PLAYER_SKILLS_ISR_CHECKBOX call _ticked;
private _jfoSkill = IDC_ADMINPANEL_PLAYER_SKILLS_JFO_CHECKBOX call _ticked;
private _uavSkill = IDC_ADMINPANEL_PLAYER_SKILLS_UAV_CHECKBOX call _ticked;
private _mksSkill = IDC_ADMINPANEL_PLAYER_SKILLS_MKS_CHECKBOX call _ticked;
private _snpSkill = IDC_ADMINPANEL_PLAYER_SKILLS_SNP_CHECKBOX call _ticked;
private _hvySkill = IDC_ADMINPANEL_PLAYER_SKILLS_HVY_CHECKBOX call _ticked;
private _rtoSkill = IDC_ADMINPANEL_PLAYER_SKILLS_RTO_CHECKBOX call _ticked;

// THIS MISSION ONLY (user, 2026-10-07: "whats done in admin is for that
// op/game only ... for it to be permanent it needs to be in pac"). With
// TAC//PAC loaded these are PAC SKILLS held for the rest of the mission -
// their ACE abilities, their arsenal lists and their tags, through respawns
// and rejoins - kept on the server and never stored (jmfsb_pac_fnc_sessionSkills).
// Ticking a box adds to the player's permanent skills; it cannot take one away.
// Leader is not here: it is a role.
if (!isNil "jmfsb_pac_fnc_sessionSkills") exitWith {
    private _skills = [];
    {
        _x params ["_has", "_skill"];
        if (_has) then {_skills pushBack _skill};
    } forEach [
        [_clsSkill, "skill:cls"], [_medSkill, "skill:medic"], [_engSkill, "skill:eng"], [_brcSkill, "skill:breacher"],
        [_isrSkill, "skill:isr"], [_jfoSkill, "skill:jfo"], [_uavSkill, "skill:uav"], [_mksSkill, "skill:marksman"], [_snpSkill, "skill:sniper"], [_hvySkill, "skill:heavy"],
        [_rtoSkill, "skill:rto"]
    ];
    [player, _player, _skills] remoteExec ["jmfsb_pac_fnc_sessionSkills", 2];
    ["Admin Panel", format ["Gave %1 these skills for this mission. Permanent skills are set in TAC//PAC.", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";
};

// Without TAC//PAC: the bare variables, as before. A medic is ACE's medic
// class 2 and a lifesaver class 1; without ACE both are the Medic trait.
private _medicClass = [[0, 1] select _clsSkill, 2] select _medSkill;
private _engineerClass = [0, 1] select _engSkill;
_player setVariable ["ace_medical_medicClass", _medicClass, true];
_player setVariable ["ACE_IsEngineer", _engineerClass, true];
_player setVariable ["ACE_isEOD", _brcSkill, true];
_player setVariable ["isISR", _isrSkill, true];
_player setVariable ["isJFO", _jfoSkill, true];
_player setVariable ["UAVHacker", _uavSkill, true];
// the RTO job (jmfsb_voice_fnc_isRto reads this flag; user, 2026-10-23)
_player setVariable ["isRTO", _rtoSkill, true];

// setUnitTrait needs the unit local, so run on the unit's machine
[_player, ["Medic", _medicClass > 0]] remoteExecCall ["setUnitTrait", _player];
[_player, ["Engineer", _engineerClass > 0]] remoteExecCall ["setUnitTrait", _player];
[_player, ["ExplosiveSpecialist", _brcSkill]] remoteExecCall ["setUnitTrait", _player];
[_player, ["UAVHacker", _uavSkill]] remoteExecCall ["setUnitTrait", _player];

["Admin Panel", format ["Applied skills to %1!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
playSound "3DEN_notificationDefault";
