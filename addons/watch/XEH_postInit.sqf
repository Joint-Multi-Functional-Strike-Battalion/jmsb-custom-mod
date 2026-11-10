#include "script_component.hpp"

// ---- the server: the shared contacts (recon, engineer threats) ---------------------
[QGVAR(contactAdd), FUNC(contactAdd)] call CBA_fnc_addEventHandler;
[QGVAR(contactDrop), FUNC(contactDrop)] call CBA_fnc_addEventHandler;
[QGVAR(contactShare), FUNC(contactShare)] call CBA_fnc_addEventHandler;
// a slot another player shared with this one (F2, FUNC(slotShare))
[QGVAR(slotShared), FUNC(slotShared)] call CBA_fnc_addEventHandler;
if (isServer) then {
    [FUNC(contactTick), TICK_SECONDS] call CBA_fnc_addPerFrameHandler;
};

if (!hasInterface) exitWith {};

// ---- the built-in profiles ------------------------------------------------------------
// SELF AID - everyone, one slot, the player himself (its setting turns it on).
["self_aid", createHashMapFromArray [
    ["name", "Self aid"], ["icon", ICON_SELF], ["slots", 1], ["order", 100],
    ["gate", {true}], ["accepts", {false}],
    ["row", FUNC(selfAidRow)], ["hud", false]
]] call FUNC(register);

// RECON - everyone (decided 2026-11-07): look at an enemy man or vehicle, 9.
// The box and the map track are the shared contact's (FUNC(contactDraw),
// FUNC(contactMarkers)), so the slot draws no panel of its own.
["recon", createHashMapFromArray [
    ["name", "Recon"], ["icon", ICON_RECON], ["order", 20],
    ["gate", {true}],
    ["accepts", {
        params ["_target"];
        alive _target && {_target isKindOf "CAManBase" || {_target isKindOf "AllVehicles"}}
            && {[side group player, side _target] call BIS_fnc_sideIsEnemy}
    }],
    ["row", FUNC(reconRow)], ["hud", false],
    ["report", FUNC(reconReport)],
    ["share", {params ["_target"]; [QGVAR(contactShare), [_target]] call CBA_fnc_serverEvent}],
    ["actions", [
        ["Map", {params ["_target"]; [_target, "recon"] call FUNC(contactMark)}],
        ["Share", {params ["_target"]; [QGVAR(contactShare), [_target]] call CBA_fnc_serverEvent}]
    ]],
    ["onAdd", {params ["_target"]; [QGVAR(contactAdd), [_target, "recon", player]] call CBA_fnc_serverEvent}],
    ["onRemove", {params ["_target"]; [QGVAR(contactDrop), [_target, player]] call CBA_fnc_serverEvent}],
    ["keep", {params ["_target"]; (GVAR(contactList) findIf {(_x # 0) isEqualTo _target}) >= 0}]
]] call FUNC(register);

// ENGINEER - ACE engineer or EOD (design): a mine or explosive he looks at, or a
// friendly vehicle (its repair look). Threats near him are found by
// FUNC(threatScan) without the key.
["engineer", createHashMapFromArray [
    ["name", "Engineer"], ["icon", ICON_ENGINEER], ["order", 30],
    ["header", FUNC(ownCharges)],
    ["gate", {[player] call FUNC(isEngineer)}],
    ["accepts", {
        params ["_target"];
        _target in allMines || {
            _target isKindOf "AllVehicles" && {!(_target isKindOf "CAManBase")} && {alive _target}
                && {!([side group player, side _target] call BIS_fnc_sideIsEnemy)}
        }
    }],
    ["row", FUNC(engineerRow)], ["hud", true], ["hudOn", FUNC(goggles)],
    ["report", FUNC(engineerReport)],
    ["share", {params ["_target"]; [QGVAR(contactShare), [_target]] call CBA_fnc_serverEvent}],
    ["actions", [
        ["Map", {params ["_target"]; [_target, "threat"] call FUNC(contactMark)}],
        ["Share", {params ["_target"]; [QGVAR(contactShare), [_target]] call CBA_fnc_serverEvent}]
    ]],
    ["onAdd", {params ["_target"]; if (_target in allMines) then {[QGVAR(contactAdd), [_target, "threat", player]] call CBA_fnc_serverEvent}}],
    ["onRemove", {params ["_target"]; if (_target in allMines) then {[QGVAR(contactDrop), [_target, player]] call CBA_fnc_serverEvent}}]
]] call FUNC(register);

// TEAM LEAD - team leads and ATLs (the role's isLeader), own squad only
// (decided 2026-11-07). F4 is the squad view. Asked before medical: 9 on his
// own man is the team lead panel; his vitals stay on ACE > Show vitals (AiTR).
["team_lead", createHashMapFromArray [
    ["name", "Team lead"], ["icon", ICON_LEAD], ["order", 5],
    ["gate", {(player getVariable ["isLeader", false]) isEqualTo true}],
    ["accepts", {params ["_target"]; _target isKindOf "CAManBase" && {_target in units group player}}],
    ["row", FUNC(leadRow)], ["hud", true], ["hudOn", FUNC(goggles)],
    ["squad", {["toggle"] call FUNC(squadView)}]
]] call FUNC(register);

// ---- the keys ---------------------------------------------------------------------
// THE ACTION KEY - F9, or numpad 9 in the numpad layout: the device's key
// layout names the default (jmfsb_devices_fnc_keyDefault) and, in the F-row
// layout, keeps the engine off the key (jmfsb_devices_fnc_keyOwned).
private _actionKey = [ACTION_KEY, [false, false, false]];
if (!isNil QEFUNC(devices,keyDefault)) then {_actionKey = [QGVAR(action), _actionKey] call EFUNC(devices,keyDefault)};
[
    JMFSB_CATEGORY, QGVAR(action),
    ["Action key", "Context action on what you look at: adds it to your watch (a medic's patient, a contact...), or takes it off again. F9 by default (numpad layout: Numpad 9)."],
    {([] call FUNC(actionKey)) || {!isNil QEFUNC(devices,keyOwned) && {[] call EFUNC(devices,keyOwned)}}}, {false},
    _actionKey
] call CBA_fnc_addKeybind;

// The panel on the device, and the F-keys while a profile is on.
if (!isNil QEGVAR(devices,overlayScreens)) then {
    EGVAR(devices,overlayScreens) set [SCREEN_ID, FUNC(screen)];
    EGVAR(devices,buttonHooks) set [HOOK_ID, FUNC(button)];
};

// ---- what is drawn ------------------------------------------------------------------
addMissionEventHandler ["Draw3D", {[] call FUNC(draw); [] call FUNC(contactDraw); [] call FUNC(jfoDraw)}];
[FUNC(tick), TICK_SECONDS] call CBA_fnc_addPerFrameHandler;

// The per-slot actions: ACE self-interaction > WATCH.
if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    private _action = [QGVAR(menu), "Watch", ACE_ICON, {}, {[] call FUNC(current) isNotEqualTo ""}, {[] call FUNC(selfMenu)}] call ace_interact_menu_fnc_createAction;
    ["CAManBase", 1, ["ACE_SelfActions"], _action, true] call ace_interact_menu_fnc_addActionToClass;
};
