#include "script_component.hpp"
/*
 * Author: YonV
 * THE MISSION HAS HANDED ITS CONFIGS OVER - build the databases from them.
 *
 * THIS EXISTS BECAUSE OF THE ORDER CBA RUNS THINGS IN. Extended_PreInit
 * handlers from addons (configFile) run BEFORE the ones from the mission
 * (missionConfigFile), so this addon's own preInit is always too early: it asks
 * for jmfsbFR_missionConfig_* before the mission's config\loadConfigs.sqf has set
 * them. Building at preInit alone would give every mission an empty logistics
 * database and no pylons, silently.
 *
 * So the mission calls this the moment its data is ready, and preInit calls it
 * too. Whichever happens first does the work; the second finds it already done.
 * A mission that hands nothing over gets empty databases and says so once,
 * which is the right answer for a mission that carries no catalogues.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The databases were built from real data <BOOL>
 *
 * Example:
 * call jmfsb_init_fnc_missionConfigsReady
 *
 * Public: Yes
 */

// IDEMPOTENT ON PURPOSE - see above, this is called from two places by design
// and the second caller must not rebuild what the first already built.
if (GVAR(configsBuilt)) exitWith {false};

// THE DATABASE FILLS WHAT THE MISSION DID NOT. A mission that ships
// config_logistics.sqf sets the global itself and this leaves it alone; one
// that ships no config folder gets it from <unit>.logistics instead. Only ever
// a fallback, so nothing a mission supplies is overridden from a website.
if (!isNil "jmfsb_pac_fnc_cfgCode") then {
    {
        _x params ["_doc", "_global", "_wrap", "_callIt"];
        if ((missionNamespace getVariable [_global, []]) isEqualTo []) then {
            private _code = [_doc, _wrap] call jmfsb_pac_fnc_cfgCode;
            if (_code isNotEqualTo {}) then {
                // logistics and pylons are tables the file RETURNS, so the
                // compiled code is called; the skill block is handed over as
                // code and called later, once per AI unit.
                missionNamespace setVariable [_global, [_code, call _code] select _callIt];
            };
        };
    } forEach [
        ["logistics", "jmfsbFR_missionConfig_logistics", "", true],
        ["pylons",    "jmfsbFR_missionConfig_pylons",    "", true],
        ["skill",     "jmfsbFR_missionConfig_skillBlock", "private _unit = _this; ", false]
    ];
};

private _haveLogistics = (missionNamespace getVariable ["jmfsbFR_missionConfig_logistics", []]) isNotEqualTo [];
private _havePylons = (missionNamespace getVariable ["jmfsbFR_missionConfig_pylons", []]) isNotEqualTo [];

// NOTHING YET IS NOT AN ERROR. preInit reaches here before the mission's own
// handler has run, every time. It leaves the flags down and returns; the
// mission's call is the one that finds the data and does the work.
if (!_haveLogistics && {!_havePylons}) exitWith {false};

GVAR(configsBuilt) = true;

// THE FLAGS BRACKET THE BUILD so a consumer that starts early can tell
// "not built yet" from "built and empty".
EGVAR(DATABASE,DONE) = false;
GVAR(DATABASE) = call FUNC(logistics);
EGVAR(DATABASE,DONE) = true;

EGVAR(PYLONS,DONE) = false;
GVAR(PYLONS) = call FUNC(pylons);
EGVAR(PYLONS,DONE) = true;

// The skill block is the mission's own compiled code - see FUNC(skillAdjustment).
if (EGVAR(Settings,setAiSystemDifficulty) >= 1) then {
    call FUNC(skillAdjustment);
};

INFO_2("preInit","Mission configs built - %1 logistics entries and %2 pylon vehicles.",count GVAR(DATABASE),count GVAR(PYLONS));

true
