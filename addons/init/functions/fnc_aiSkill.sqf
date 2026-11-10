#include "script_component.hpp"
/*
 * Author: YonV
 * The skill one AI gets, from the settings.
 *
 * THIS REPLACES config\config_skill.hpp (2026-09-09). That was a block of SQF
 * the mission compiled and handed over, so changing how hard the AI shoot meant
 * editing a file, repacking the mission and restarting the server. Every number
 * it set is a CBA setting now - see aiSkillSettings.inc.sqf - and the whole
 * thing is edited in the settings menu by whoever is running the night.
 *
 * WHAT IT DOES, in the order it does it:
 *   1. the nine base skills, on every AI
 *   2. after dark, spotting is cut - hard when the AI has no night vision,
 *      which is the single thing that decides whether a night op feels fair
 *   3. machinegunners and snipers get their own aim, if that is switched on
 *
 * A MISSION THAT STILL SHIPS A SKILL BLOCK WINS. jmfsbFR_missionConfig_skillBlock
 * is called instead when it exists, so a mission carrying its own file behaves
 * exactly as it did - this is the answer for every mission that does not.
 *
 * CALLED ONCE PER AI, and an ALiVE session creates them in four figures - 1618
 * in a 21-minute session, in bursts of ~370 a minute. So: no logging, no config
 * lookups beyond the one this cannot avoid, and every setting read straight
 * from its variable.
 *
 * Arguments:
 * 0: The unit <OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {};

// The mission's own block, when it has one - see above.
private _own = missionNamespace getVariable ["jmfsbFR_missionConfig_skillBlock", {}];
if (_own isNotEqualTo {}) exitWith {_unit call _own};

// ---- the nine ---------------------------------------------------------------
_unit setSkill ["general",        EGVAR(Settings,aiGeneral)];
_unit setSkill ["commanding",     EGVAR(Settings,aiCommanding)];
_unit setSkill ["courage",        EGVAR(Settings,aiCourage)];
_unit setSkill ["aimingSpeed",    EGVAR(Settings,aiAimingSpeed)];
_unit setSkill ["aimingAccuracy", EGVAR(Settings,aiAimingAccuracy)];
_unit setSkill ["aimingShake",    EGVAR(Settings,aiAimingShake)];
_unit setSkill ["reloadSpeed",    EGVAR(Settings,aiReloadSpeed)];

// ---- spotting, which depends on the light ----------------------------------
// getLighting's second element is the moon's contribution; at 5 or less it is
// dark enough that eyes alone are not enough. The number is the old block's.
private _spotTime = EGVAR(Settings,aiSpotTime);
private _spotDist = EGVAR(Settings,aiSpotDistance);

if (EGVAR(Settings,aiNightApplies) && {(getLighting select 1) <= 5}) then {
    // hmd is the cheapest way to ask "can this one see in the dark" - it is
    // what the old block asked, and it is a variable read rather than a config
    // walk, which matters at four figures of units a session.
    if ((hmd _unit) isNotEqualTo "") then {
        _spotTime = EGVAR(Settings,aiNightSpotTime);
        _spotDist = EGVAR(Settings,aiNightSpotDistance);
    } else {
        _spotTime = EGVAR(Settings,aiBlindSpotTime);
        _spotDist = EGVAR(Settings,aiBlindSpotDistance);
    };
};

_unit setSkill ["spotTime",     _spotTime];
_unit setSkill ["spotDistance", _spotDist];

// ---- the two trades that are meant to shoot better --------------------------
if (!EGVAR(Settings,aiRoleApplies)) exitWith {};

// ONE CONFIG READ, CACHED BY TYPE. textSingular is a config lookup and this
// runs per unit; a mission that spawns four hundred riflemen of one type in a
// minute should walk the config once, not four hundred times.
if (isNil QGVAR(aiTrade)) then {GVAR(aiTrade) = createHashMap};
private _type = typeOf _unit;
private _trade = GVAR(aiTrade) getOrDefaultCall [_type, {
    toLower getText (configFile >> "CfgVehicles" >> _type >> "textSingular")
}, true];

switch (_trade) do {
    case "machinegunner": {
        _unit setSkill ["aimingSpeed",    EGVAR(Settings,aiMgAimingSpeed)];
        _unit setSkill ["aimingAccuracy", EGVAR(Settings,aiMgAimingAccuracy)];
        _unit setSkill ["aimingShake",    EGVAR(Settings,aiMgAimingShake)];
    };
    case "sniper": {
        _unit setSkill ["aimingSpeed",    EGVAR(Settings,aiSniperAimingSpeed)];
        _unit setSkill ["aimingAccuracy", EGVAR(Settings,aiSniperAimingAccuracy)];
        _unit setSkill ["aimingShake",    EGVAR(Settings,aiSniperAimingShake)];
    };
    default {};
};
