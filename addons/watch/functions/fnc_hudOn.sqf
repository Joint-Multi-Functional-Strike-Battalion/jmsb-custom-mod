#include "script_component.hpp"
/*
 * Author: YonV
 * Whether this player draws a profile in the world - his HUD setting for it
 * (a server or mission may force it). A profile with no setting draws.
 *
 * Arguments:
 * 0: Profile id <STRING>
 *
 * Return Value:
 * Drawn <BOOL>
 *
 * Example:
 * ["medical"] call jmfsb_watch_fnc_hudOn
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

switch (_id) do {
    case "medical": {GVAR(hud_medical)};
    case "team_lead": {GVAR(hud_team_lead)};
    case "engineer": {GVAR(hud_engineer)};
    case "recon": {GVAR(hud_recon)};
    case "jfo": {GVAR(hud_jfo)};
    default {true};
}
