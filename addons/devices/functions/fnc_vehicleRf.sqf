#include "script_component.hpp"
/*
 * Author: JMSB
 * VEHICLE STATUS's voice section: the nets the player is on while aboard, as
 * the voice API has them (docs/DESIGN_VOICE.md, "Nets on the devices"). VEH -
 * the crew intercom, VON's Vehicle channel - is listed because he is inside;
 * every other net is whatever he holds anyway. Each is reachable or not; the
 * active one is marked.
 *
 * READ, NEVER COMPUTED (docs/DESIGN_TABLET_APPS.md: an app only reads data its
 * owner already has). There is no radio rack any more: VON has no sets, only
 * channels, and the mesh decides who hears whom.
 *
 * Arguments:
 * 0: The vehicle <OBJECT>
 *
 * Return Value:
 * 0: State - "off" (no voice addon), "none" (not aboard), "on" <STRING>
 * 1: One entry per net: [name <STRING>, reachable <BOOL>, active <BOOL>, kind <STRING>] <ARRAY>
 *
 * Example:
 * ([vehicle player] call jmfsb_devices_fnc_vehicleRf) params ["_state", "_nets"]
 *
 * Public: No
 */

params [["_vehicle", objNull, [objNull]]];

if (isNil QEFUNC(voice,netState)) exitWith {["off", []]};
if (isNull _vehicle || {!((call CBA_fnc_currentUnit) in crew _vehicle)}) exitWith {["none", []]};

private _nets = [];
{
    _x params [["_netId", "", [""]], ["_name", "", [""]], ["_kind", "", [""]], ["_active", false, [false]], "", "", ["_reach", false, [false]]];
    if (_kind isEqualTo VOICE_KIND_DIRECT || _netId isEqualTo "") then {continue};
    _nets pushBack [toUpper _name, _reach, _active, _kind];
} forEach ([] call EFUNC(voice,netState));

["on", _nets]
