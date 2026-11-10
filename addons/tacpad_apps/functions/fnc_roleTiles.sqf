#include "script_component.hpp"
/*
 * Author: YonV
 * Which live tiles a man's ROLE lets him see, read off the role itself - the
 * unit's database copy when TAC//PAC holds the roles there, the mission's
 * own class otherwise (jmfsb_groups_fnc_role). The same shape and the same
 * rules as the net gate in EFUNC(messaging,roleNets).
 *
 *   class jfoNomad {
 *       tiles[] = {
 *           {"weather", "true"},
 *           {"timer", "true"}
 *       };
 *   };
 *
 * NO CONFIGURED VALUE, NO ACCESS. A tile absent from the list is not his, and a
 * role that lists none sees none - the band comes up empty rather than coming up
 * with everything.
 *
 * THE FEATURE IS OFF UNTIL SOMEBODY USES IT. If no role in the mission declares
 * tiles[] at all, the gate does not exist and every tile shows as it always did.
 * Without that, adding this to a mission that never asked for tile gating would
 * silently take the whole band away from everybody.
 *
 * A DENIED TILE IS NOT DRAWN AT ALL - not greyed, not stubbed. It is filtered
 * out of FUNC(tileData), which is the only place tiles come from, so the app
 * behind it cannot be reached either: clicking a tile is the only way into an
 * app.
 *
 * The role itself is the mission's own record: setupPlayer writes the chosen
 * role class to YMF_role on the man.
 *
 * Arguments:
 * 0: The man <OBJECT>
 *
 * Return Value:
 * 0: The gate is in force <BOOL> - false means "no gating in this mission"
 * 1: Tile ids he may see <ARRAY>
 *
 * Example:
 * ([player] call jmfsb_tacpad_apps_fnc_roleTiles) params ["_gated", "_allowed"];
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

// Is anybody using this? The roles come off jmfsb_groups_fnc_roles - the
// database's when the unit keeps them there, the mission's otherwise - and
// they can change under a running client (a new structure from the server),
// so it is answered per call: two dozen hashmap reads per redraw, not a
// config walk. Gated means some role lists a tile; a role that lists none
// sees none.
private _roles = if (!isNil "jmfsb_groups_fnc_roles") then {[] call jmfsb_groups_fnc_roles} else {createHashMap};
private _gated = false;
{
    if (_y isEqualType createHashMap && {(_y getOrDefault ["tiles", []]) isNotEqualTo []}) exitWith {_gated = true};
} forEach _roles;
if ((missionNamespace getVariable [QGVAR(roleTilesGated), !_gated]) isNotEqualTo _gated) then {
    GVAR(roleTilesGated) = _gated;
    // Hoisted: a comma inside a macro argument reads as an argument separator.
    private _said = ["off - no role declares tiles", "ON - roles without tiles get none"] select _gated;
    INFO_1("role tile gating is %1",_said);
};

if (!_gated) exitWith {[false, []]};
if (isNull _unit) exitWith {[true, []]};

private _role = _unit getVariable ["YMF_role", ""];
if (_role isEqualTo "") exitWith {[true, []]};

private _cfg = (_roles getOrDefault [_role, createHashMap]) getOrDefault ["tiles", []];
if !(_cfg isEqualType []) exitWith {[true, []]};

private _out = [];

{
    _x params [["_name", ""], ["_flag", "true"]];
    if (!(_name isEqualType "") || _name isEqualTo "") then {continue};

    // The flag is a string in the role configs ("true"), because that is how
    // traits, customVariables and nets[] are written there; a real boolean is
    // taken too rather than being quietly ignored.
    private _on = if (_flag isEqualType "") then {
        (toLower trim _flag) in ["true", "1", "yes"]
    } else {
        _flag isEqualTo true || _flag isEqualTo 1
    };

    if (_on) then {_out pushBackUnique (toLower _name)};
} forEach _cfg;

[true, _out]
