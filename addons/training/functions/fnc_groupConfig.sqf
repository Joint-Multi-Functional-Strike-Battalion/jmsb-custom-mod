#include "script_component.hpp"
/*
 * Author: YonV
 * A CfgGroups class name to its config - CfgGroups >> side >> faction >>
 * category >> group. Indexed on first use. A name two factions share resolves
 * to the first found; pass the config itself to be exact.
 *
 * Arguments:
 * 0: Group class name, or a config (returned as is) <STRING, CONFIG>
 *
 * Return Value:
 * The group's config, configNull when there is none <CONFIG>
 *
 * Example:
 * ["O_T_InfSquad"] call jmfsb_training_fnc_groupConfig
 *
 * Public: No
 */

params [["_group", "", ["", configNull]]];

if (_group isEqualType configNull) exitWith {_group};

if (isNil QGVAR(groupIndex)) then {
    GVAR(groupIndex) = createHashMap;
    {
        {
            {
                {
                    private _key = toLower configName _x;
                    if !(_key in GVAR(groupIndex)) then {
                        GVAR(groupIndex) set [_key, _x];
                    };
                } forEach ("true" configClasses _x);
            } forEach ("true" configClasses _x);
        } forEach ("true" configClasses _x);
    } forEach ("true" configClasses (configFile >> "CfgGroups"));
};

GVAR(groupIndex) getOrDefault [toLower trim _group, configNull]
