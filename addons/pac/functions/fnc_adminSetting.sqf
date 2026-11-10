#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_adminSetting

Description:
    An admin changes one of the unit's SETTINGS, on the server, checked the way
    every other admin door is checked.

    SIMPLE OR REAL WORLD TEMPLATES (user, 2026-11-09): TEMPLATE_FORM_KEY too,
    "real" or "simple" only, and it takes effect at once
    (FUNC(templateFormPublish)) - not at the next mission start.

    ONLY THE "WHICH VERSION" ONES. A unit keeps several orders of battle,
    arsenals, briefings and orders, and these settings say which of them is the
    unit's default - so this is how the in-game editor ticks one LIVE. Every
    other setting either belongs to the server (unitId, serverId, sync - a
    database cannot tell a server where the database is) or has its own screen.

    THE DEFAULT, NOT THE LAW. A mission that names a version in its own
    CfgGFA_PAC keeps that one whatever is set here - see FUNC(structureAdopt).
    Read at the next mission start; the one already running keeps what it
    booted with.

Parameters:
    0: Caller <OBJECT>
    1: Setting <STRING>
    2: Value <STRING>

Returns:
    Whether it was set <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_key", "", [""]], ["_value", "", [""]]];

if (!isServer) exitWith {false};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {
    WARNING_2("adminSetting refused: %1 is not an admin (%2)",name _caller,_key);
    false
};
if (GVAR(readOnly)) exitWith {false};

private _fnc_tell = {
    params ["_msg", "_bad"];
    ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

// The version settings, from the same table the fetch uses, plus the two that
// are fetched by name. Anything else is refused rather than quietly written.
private _allowed = ((([] call FUNC(svcSections)) apply {_x # 2}) select {_x isNotEqualTo ""})
    + ["currentOrbat", "currentWelcome", "currentOpord", TEMPLATE_FORM_KEY];
if !(_key in _allowed) exitWith {
    [format ["'%1' is not a setting this can change.", _key], true] call _fnc_tell;
    false
};

if (_key isEqualTo TEMPLATE_FORM_KEY && {!(_value in TEMPLATE_FORMS)}) exitWith {
    [format ["'%1' is not a template form - %2.", _value, TEMPLATE_FORMS joinString " or "], true] call _fnc_tell;
    false
};

GVAR(settings) set [_key, _value];
["settings"] call FUNC(structurePersist);
[getPlayerUID _caller, name _caller, "settings", _key, format ["%1 = '%2'", _key, _value]] call FUNC(logAction);

INFO_3("%1 set %2 to '%3'",name _caller,_key,_value);
if (_key isEqualTo TEMPLATE_FORM_KEY) exitWith {
    [] call FUNC(templateFormPublish);
    [format ["Templates are now %1 - cards open in that form from now on.", ["REAL WORLD", "SIMPLE"] select (_value isEqualTo TEMPLATE_FORM_SIMPLE)], false] call _fnc_tell;
    true
};
[format ["%1 is now '%2'. Read at the next mission start.", _key, [_value, "the common one"] select (_value isEqualTo "")], false] call _fnc_tell;
true
