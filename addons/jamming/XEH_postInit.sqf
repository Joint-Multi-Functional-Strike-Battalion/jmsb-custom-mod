#include "script_component.hpp"

// Client: the jamming applier. No side gate - a zone degrades whoever stands
// in it, because the zones belong to objectives rather than to a module that
// named a victim.
if (hasInterface) then {
    GVAR(acreJam) = 0;
    GVAR(hasACRE) = isClass (configFile >> "CfgPatches" >> "acre_main");

    [LINKFUNC(jammerLoop), JAM_CHECK_INTERVAL, []] call CBA_fnc_addPerFrameHandler;

    // The static-wash HUD was PREPed, documented and never registered -
    // FUNC(jamHud) had no caller at all. It draws from the loop's own
    // localJamFactor, so it rides the same cadence.
    [LINKFUNC(jamHud), JAM_CHECK_INTERVAL, []] call CBA_fnc_addPerFrameHandler;

    // The GPS denial is a UI switch, not a loadout change, so a respawn has
    // nothing to restore - but the switch itself is global and survives the
    // body, so a man who died inside a field would come back with the display
    // still dark until the next tick corrected it. Cleared on both events.
    ["ace_playerChanged", { GVAR(gpsDenied) = false; showGPS true }] call CBA_fnc_addEventHandler;
    ["unit", { GVAR(gpsDenied) = false; showGPS true }] call CBA_fnc_addPlayerEventHandler;

    // ACRE2: keep the vanilla signal result but scale received strength by
    // this player's live jam level. jam == 0 is identical to vanilla.
    //
    // ACRE ALLOWS ONE CUSTOM SIGNAL FUNCTION. When jmfsb_radio_mesh is loaded
    // it owns it - it routes through relays and then applies GVAR(acreJam)
    // itself (see radio_mesh/fnc_signal), so this one stands down.
    if (GVAR(hasACRE) && {!isNil "acre_api_fnc_setCustomSignalFunc"}
        && {!isClass (configFile >> "CfgPatches" >> "jmfsb_radio_mesh")}) then {
        [{
            private _core = _this call acre_sys_signal_fnc_getSignalCore;
            private _jam = missionNamespace getVariable [QGVAR(acreJam), 0];
            // and the RF burst's registry (jmfsb_aps) - the same lever, another source
            _jam = _jam max (missionNamespace getVariable ["jmfsb_aps_acreJam", 0]);
            if (_jam <= 0) exitWith { _core };
            _core params ["_pct", "_dbm"];
            [_pct * (1 - _jam), _dbm]
        }] call acre_api_fnc_setCustomSignalFunc;
    };
};

if (!isServer) exitWith {};

// RADIO AND DATA ZONES ARE RF NOISE: RF prices them into every link budget on
// the server, and voice and data degrade by SNR from there. With no zones the
// hook returns nothing at once.
[{_this call FUNC(rfNoise)}] call EFUNC(rf,addNoiseSource);

// THE MODULE IS THE ENABLE. This file only sets up state and the report
// command; FUNC(moduleController) is what arms the system, so a mission with
// no module placed gets nothing from this addon. GVAR(moduleUp) is declared in
// XEH_preInit, NOT here - see there for why.

["jmfsbjam", {
    [QGVAR(report), []] call CBA_fnc_serverEvent;
}, "all"] call CBA_fnc_registerChatCommand;

[QGVAR(report), {
    private _z = ["all", [], true] call FUNC(getZones);
    private _txt = format ["%1 zone(s): %2", count _z,
        _z apply {format ["%1@%2 r=%3", _x select 1, mapGridPosition (_x select 2), round (_x select 3)]}];
    diag_log text format ["[jmfsb_jamming] %1", _txt];
    [format ["JAMMING: %1", _txt]] remoteExec ["systemChat", 0];
}] call CBA_fnc_addEventHandler;
