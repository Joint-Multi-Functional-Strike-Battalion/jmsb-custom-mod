#include "script_component.hpp"
/*
 * Author: JMSB
 * HACK - the rows of NODES IN REACH: the intrusion suite's own device list
 * (jmfsb_hacking_devices, from its scan - towers, hostile drones, wrecks, enemy
 * nets) joined to what RF says the player's set can hear
 * (jmfsb_hacking_rfReach, the server's answer through RF's public calls).
 *
 * A suite device carries its slot in the suite's list, so selecting it is the
 * suite's own tabletSelectDevice and the action is the suite's own. An RF node
 * no suite device stands for is listed too - the player can hear it - but has
 * slot -1: there is nothing in the suite to break into it with, and the row
 * says NO ACCESS rather than offering a press that does nothing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Rows, each [slot (-1 = none), object, node, type, distance, range, security,
 * RF quality (QUALITY_UNKNOWN when RF did not answer for it)] <ARRAY>
 *
 * Example:
 * private _rows = [] call jmfsb_tacpad_apps_fnc_appHackNodes
 *
 * Public: No
 */

private _devices = missionNamespace getVariable [QEGVAR(hacking,devices), []];
private _rf = missionNamespace getVariable [QEGVAR(hacking,rfReach), []];
private _cooldown = if (isNil QEFUNC(hacking,hackSetting)) then {0} else {[QEGVAR(hacking,cfg_hack_cooldown)] call EFUNC(hacking,hackSetting)};
private _used = [];
private _out = [];

{
    _x params ["_obj", "_kind", "_label", "_dist", "_range"];

    // RF nodes held by this device - or, for a net, by anyone in its group.
    private _mine = _rf select {
        private _holder = _x select 0;
        _holder isEqualTo _obj || {_kind isEqualTo "unit" && {(group _holder) isEqualTo (group _obj)}}
    };
    _used append _mine;
    private _q = QUALITY_UNKNOWN;
    {_q = _q max (_x select 3)} forEach _mine;
    private _ownKey = (_mine findIf {_x select 4}) >= 0;

    private _security = switch (_kind) do {
        case "tower": {
            private _last = _obj getVariable [QEGVAR(hacking,lastHack), HACKAPP_NEVER];
            switch (true) do {
                case (_cooldown < 0 && {_last > HACKAPP_NEVER / 2}): {"SPENT"};
                case (_cooldown >= 0 && {(CBA_missionTime - _last) < _cooldown}): {"COOLING"};
                default {"OPEN"};
            }
        };
        case "drone": {"LINK"};
        case "wreck": {"NONE"};
        default {
            switch (true) do {
                case (_ownKey): {"OWN KEY"};
                case (_mine isNotEqualTo []): {"SIDE KEY"};
                default {"PHONE"};
            }
        };
    };
    private _type = switch (_kind) do {
        case "tower": {"TOWER"};
        case "drone": {"DRONE"};
        case "wreck": {"WRECK"};
        default {["NET", toUpper ((_mine param [0, []]) param [2, "NET"])] select (_mine isNotEqualTo [])};
    };
    _out pushBack [_forEachIndex, _obj, _label, _type, _dist, _range, _security, _q];
} forEach _devices;

// What RF hears that the suite has no way into.
{
    _x params ["_holder", "_id", "_profile", "_q", "_ownKey"];
    if (isNull _holder) then {continue};
    private _label = if (_holder isKindOf "CAManBase") then {format ["NET - %1", groupId group _holder]} else {toUpper getText (configOf _holder >> "displayName")};
    _out pushBack [-1, _holder, _label, toUpper _profile, player distance _holder, -1, ["SIDE KEY", "OWN KEY"] select _ownKey, _q];
} forEach (_rf - _used);

_out
