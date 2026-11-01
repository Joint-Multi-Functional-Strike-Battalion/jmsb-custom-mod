#include "script_component.hpp"

// Client: the jamming applier. No side gate - a zone degrades whoever stands
// in it, because the zones belong to objectives rather than to a module that
// named a victim.
if (hasInterface) then {
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
};

// ACE ON THE TERMINAL ITSELF (user, 2026-10-24: "the jammers need to have a
// local ace interface to disable or hack"). Two actions under the terminal's
// own menu, on the three terminal classes, shown only while the thing is a
// live jammer: DISABLE kneels for the disable time and ends the zone for good
// (an engineer's job by default); HACK puts it on the HACK board and opens the
// board. ACE is not required by this addon, so both are guarded.
if (hasInterface && {!isNil "ace_interact_menu_fnc_createAction"}) then {
    private _disable = [
        QGVAR(disable), "Disable jammer", JAM_ACTION_ICON,
        {params ["_target", "_player"]; [_target, _player] call FUNC(disableStart)},
        {params ["_target", "_player"]; [_target, _player] call FUNC(canDisable)}
    ] call ace_interact_menu_fnc_createAction;
    private _hack = [
        QGVAR(hack), "Hack jammer", JAM_ACTION_ICON,
        {params ["_target", "_player"]; [_target, _player] call FUNC(hackStart)},
        {
            params ["_target", "_player"];
            !isNil QEFUNC(hacking,canHack)
            && {[_target] call FUNC(isLiveJammer)}
            && {[_player] call EFUNC(hacking,canHack)}
        }
    ] call ace_interact_menu_fnc_createAction;
    {
        if (isClass (configFile >> "CfgVehicles" >> _x)) then {
            [_x, 0, ["ACE_MainActions"], _disable, false] call ace_interact_menu_fnc_addActionToClass;
            [_x, 0, ["ACE_MainActions"], _hack, false] call ace_interact_menu_fnc_addActionToClass;
        };
    } forEach JAM_PROP_TERMINALS;
    // What the server says back to the one who did it (fnc_disableSite) comes
    // through notify's broadcast - no "note" CBA event any client could raise
    // to put text on every screen (review R1).
};

// THE REPORT, admins only, answered to the caller alone (review R1: it was a
// CBA event any player could raise to print every zone's position in everyone's
// chat). On the #jmfsb surface: registered on every machine, because the
// typer's machine looks it up, and run on the server. #jmfsbjam is a shortcut.
["jam", "jamming zones and where they are", {
    private _z = ["all", [], true] call FUNC(getZones);
    private _txt = format ["%1 zone(s): %2", count _z,
        _z apply {format ["%1@%2 r=%3", _x select 1, mapGridPosition (_x select 2), round (_x select 3)]}];
    diag_log text format ["[jmfsb_jamming] %1", _txt];
    format ["JAMMING: %1", _txt]
}] call EFUNC(common,addDebugCommand);

if (hasInterface) then {
    ["jmfsbjam", {
        ["#jmfsb jam", player] call EFUNC(common,debugCommand);
    }, "all"] call CBA_fnc_registerChatCommand;
};

if (!isServer) exitWith {};
// A terminal disabled by hand (fnc_disableStart, on the client that did it)
// comes by remoteExec to FUNC(disableSite), which checks who and where.

// RADIO AND DATA ZONES ARE RF NOISE: RF prices them into every link budget on
// the server, and voice and data degrade by SNR from there. With no zones the
// hook returns nothing at once.
[{_this call FUNC(rfNoise)}] call EFUNC(rf,addNoiseSource);

// THE MODULE IS THE ENABLE. This file only sets up state and the report
// command; FUNC(moduleController) is what arms the system, so a mission with
// no module placed gets nothing from this addon. GVAR(moduleUp) is declared in
// XEH_preInit, NOT here - see there for why.

