#include "script_component.hpp"
/*
 * Author: JMSB
 * The MEDIC tile: how many of the player's squad are hurt, and an alert the
 * moment one of them is in cardiac arrest or bleeding heavily. A tile provider
 * for jmfsb_tacpad_apps' band (jmfsb_tacpad_apps_tileProviders, registered in
 * XEH_preInit), so the role gate and the band order apply to it like any tile.
 *
 * A MEDIC'S TILE ONLY. A man whose PAC skills hold neither CLS nor Medic gets
 * no tile at all - not a greyed one - and so no way into the app, because a
 * tile is the only way into an app (EFUNC(tacpad_apps,tileData)).
 *
 * Without ACE medical the tile is drawn stale and says so, rather than showing
 * a confident zero: no medical system is not the same as nobody hurt.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Tile entries, [] or one [appId, kicker, qualifier, value, detail, state] <ARRAY>
 *
 * Example:
 * [] call jmfsb_medic_fnc_tile
 *
 * Public: No
 */

if !([player] call FUNC(isMedic)) exitWith {[]};

if (!GVAR(ace)) exitWith {
    [[APP_ID, "MEDIC", "NO SYS", "-", "MEDICAL SYSTEM NOT LOADED", "stale"]]
};

private _hurt = 0;
private _down = 0;
private _arrest = 0;
private _bleeding = 0;

{
    ([_x] call FUNC(patientState)) params ["_state", "_heavy"];
    if (_state in [STATE_ARREST, STATE_UNCON, STATE_WOUNDED]) then {_hurt = _hurt + 1};
    if (_state in [STATE_ARREST, STATE_UNCON]) then {_down = _down + 1};
    if (_state isEqualTo STATE_ARREST) then {_arrest = _arrest + 1};
    if (_heavy) then {_bleeding = _bleeding + 1};
} forEach (units group player);

private _detail = switch (true) do {
    case (_arrest > 0 && _bleeding > 0): {format ["%1 ARREST - %2 BLEEDING", _arrest, _bleeding]};
    case (_arrest > 0): {format ["%1 IN CARDIAC ARREST", _arrest]};
    case (_bleeding > 0): {format ["%1 BLEEDING HEAVILY", _bleeding]};
    case (_down > 0): {format ["%1 DOWN - PRESS TO TRIAGE", _down]};
    case (_hurt > 0): {"WOUNDED - PRESS TO TRIAGE"};
    default {"SQUAD OK"};
};

[[
    APP_ID,
    "MEDIC",
    switch (true) do {
        case (_arrest > 0): {"ARREST"};
        case (_bleeding > 0): {"BLEED"};
        default {"WIA"};
    },
    str _hurt,
    _detail,
    switch (true) do {
        case (_arrest > 0 || _bleeding > 0): {"alert"};
        case (_hurt > 0): {"warn"};
        default {"rest"};
    }
]]
