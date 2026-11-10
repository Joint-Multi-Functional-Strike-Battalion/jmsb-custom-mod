#include "script_component.hpp"
/*
 * Author: YonV
 * Which nets a man's ROLE lets him onto, read off the role itself - the
 * unit's database copy when TAC//PAC holds the roles there, the mission's
 * own class otherwise (jmfsb_groups_fnc_role). Access lives with the role,
 * wherever the role lives - a mod-side setting would be a second list to
 * keep in step with the first.
 *
 * The shape is the one the role configs already use for traits: a name and
 * a flag.
 *
 *   class jfoNomad {
 *       nets[] = {
 *           {"HQ", "true"},
 *           {"AIR", "true"},
 *           {"FIRES", "true"}
 *       };
 *   };
 *
 * NO CONFIGURED VALUE, NO ACCESS - the user's rule. A net absent from the
 * list is not his, and a role that lists none gets none.
 *
 * THE FEATURE IS OFF UNTIL SOMEBODY USES IT. If no role in the mission
 * declares nets[] at all, the gate does not exist and every net reads as it
 * always did - otherwise adding this addon to a mission that never asked
 * for role gating would silently take every net away from everybody.
 *
 * The role itself is the mission's own record: setupPlayer writes the
 * chosen role class to YMF_role on the man.
 *
 * Arguments:
 * 0: The man <OBJECT>
 *
 * Return Value:
 * 0: The gate is in force <BOOL> - false means "no gating in this mission"
 * 1: Net names he may read <ARRAY>
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

// Is anybody using this? The roles come off jmfsb_groups_fnc_roles - the
// database's when the unit keeps them there, the mission's otherwise - and
// they can change under a running machine (a new structure from the server),
// so it is answered per call: two dozen hashmap reads, not a config walk.
// Gated means some role lists a net; a role that lists none gets none.
private _roles = if (!isNil "jmfsb_groups_fnc_roles") then {[] call jmfsb_groups_fnc_roles} else {createHashMap};
private _gated = false;
{
    if (_y isEqualType createHashMap && {(_y getOrDefault ["nets", []]) isNotEqualTo []}) exitWith {_gated = true};
} forEach _roles;
if ((missionNamespace getVariable [QGVAR(roleNetsGated), !_gated]) isNotEqualTo _gated) then {
    GVAR(roleNetsGated) = _gated;
    // Hoisted: a comma inside a macro argument reads as an argument separator.
    private _said = ["off - no role declares nets", "ON - roles without nets get none"] select _gated;
    INFO_1("role net gating is %1",_said);
};

if (!_gated) exitWith {[false, []]};
if (isNull _unit) exitWith {[true, []]};

private _role = _unit getVariable ["YMF_role", ""];
if (_role isEqualTo "") exitWith {[true, []]};

private _cfg = (_roles getOrDefault [_role, createHashMap]) getOrDefault ["nets", []];
if !(_cfg isEqualType []) exitWith {[true, []]};

private _out = [];
{
    _x params [["_name", ""], ["_flag", "true"]];
    if (!(_name isEqualType "") || _name isEqualTo "") then {continue};

    // The flag is a string in the role configs ("true"), because that is how
    // traits and customVariables are written there; a real boolean is taken
    // too rather than being quietly ignored.
    private _on = if (_flag isEqualType "") then {
        (toLower trim _flag) in ["true", "1", "yes"]
    } else {
        _flag isEqualTo true || _flag isEqualTo 1
    };

    if (_on) then {_out pushBackUnique _name};
} forEach _cfg;

[true, _out]
