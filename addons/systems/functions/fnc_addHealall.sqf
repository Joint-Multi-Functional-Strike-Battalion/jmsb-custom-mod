#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A
 * This adds a adda ction as well as a ACE interaction reGear selection. The script reapplyes the players start loadout.
 *
 * The heal itself is the server's (FUNC(srvHealAll), by remoteExec - review
 * R1): the healed were told through the notify post CBA event, which any
 * client could aim at anyone.
 *
 * Arguments:
 * 0: Object <OBJECT>
 *
 * Example:
 * [this] call jmfsb_systems_fnc_addHealall;
 */

params [
    ["_object", objNull, [objNull]],
    ["_category", ["ACE_MainActions"], [["ACE_MainActions"]]]
];


// Make addAction
if (!isPlayer _object) then {
    _object addAction ["   <t color='#ff3333'>Heal All Within 12M</t>", {
        params ["_target"];
        [_target] remoteExecCall [QFUNC(srvHealAll), SERVER_OWNER];
        ["Medical", "Healed everyone except that guy.", NOTE_GOOD] call JMFSBFUNC(notify,notify);
    }, [], 1.5, true, true, "", "", 5];
};

// Make ACE Interaction for ReGear
private _healStatement = {
    [_target] remoteExecCall [QFUNC(srvHealAll), SERVER_OWNER];
    ["Medical", "Healed everyone except that guy.", NOTE_GOOD] call JMFSBFUNC(notify,notify);
};

private _healallAction = [QEGVAR(Actions,HealallAction), "Heal All Within 12M", "\z\ACE\addons\medical_gui\ui\cross.paa", _healStatement, {true}] call ace_interact_menu_fnc_createAction;
[_object, 0, _category, _healallAction] call ace_interact_menu_fnc_addActionToObject;

true
