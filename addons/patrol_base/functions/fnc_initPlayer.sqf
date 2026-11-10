#include "script_component.hpp"
/*
 * Author: YonV
 * Sets up the player-facing "Establish Patrol Base" action: ACE self-interaction
 * when ACE is present, otherwise a scroll action. Shows for any player on foot
 * with enough kits down, when the system is enabled.
 *
 * Arguments: None
 * Return Value: None
 *
 * Public: No
 */

if !(hasInterface) exitWith {};

if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    private _condition = {
        alive ACE_player
        && {isNull objectParent ACE_player}
        && {missionNamespace getVariable [QGVAR(enabled), true]}
        && {count (missionNamespace getVariable [QGVAR(bases), []]) < (missionNamespace getVariable [QGVAR(maxCount), 3])}
        && {([getPosATL ACE_player] call FUNC(countKits)) >= (missionNamespace getVariable [QGVAR(kitCount), 4])}
    };
    private _act = [
        QGVAR(establish),
        "Establish Patrol Base",
        "\A3\ui_f\data\IGUI\Cfg\simpleTasks\types\meet_ca.paa",
        { [] call FUNC(establishPatrolBase) },
        _condition
    ] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions"], _act] call ace_interact_menu_fnc_addActionToObject;
} else {
    player addAction [
        "<t color='#ffc61a'>Establish Patrol Base</t>",
        { [] call FUNC(establishPatrolBase) },
        nil,
        6,
        false,
        true,
        "",
        "alive _target && {_target == _this} && {isNull objectParent _target} && {missionNamespace getVariable ['jmfsb_patrol_base_enabled', true]}",
        -1,
        false
    ];
};
