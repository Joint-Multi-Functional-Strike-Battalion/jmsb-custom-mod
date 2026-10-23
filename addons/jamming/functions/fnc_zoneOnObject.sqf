#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: lays a zone on an object that already exists - a carried jammer, a
 * vehicle - rather than creating an emitter prop the way FUNC(spawnZoneAt)
 * does. The zone moves with the object (FUNC(jamFactor) reads the object's
 * position live) and dies with it. The owner tag is stamped into the zone's
 * model, so FUNC(emitters) can tell a caller which zones are its own.
 *
 * jmfsb_ew lays its GPS jammers here: GPS denial stays this addon's
 * (FUNC(gpsApply)), whoever fields the jammer.
 *
 * Arguments:
 * 0: Object <OBJECT>
 * 1: Outer radius m <NUMBER>
 * 2: Domains, of "radio" / "data" / "gps" <ARRAY of STRINGs>
 * 3: Owner tag (optional, default "") <STRING>
 *
 * Return Value:
 * Zone id, "" when refused <STRING>
 *
 * Example:
 * [_pack, 600, ["gps"], "jmfsb_ew"] call jmfsb_jamming_fnc_zoneOnObject
 *
 * Public: Yes
 */

params [
    ["_obj", objNull, [objNull]],
    ["_radius", 0, [0]],
    ["_domains", DOM_DEFAULT, [[]]],
    ["_owner", "", [""]]
];

if (!isServer || {isNull _obj} || _radius <= 0) exitWith {""};

if (isNil QGVAR(jammers)) then {GVAR(jammers) = []};
if (isNil QGVAR(nextZoneId)) then {GVAR(nextZoneId) = 1};

private _id = format [QGVAR(z%1), GVAR(nextZoneId)];
GVAR(nextZoneId) = GVAR(nextZoneId) + 1;

private _model = [_domains] call FUNC(zoneModel);
_model set ["owner", _owner];

GVAR(jammers) pushBack [
    _obj, _radius * JAMMER_EFFECTIVE_FRAC, _radius,
    _id, "jam", false, getPosASL _obj,
    _model
];
[] call FUNC(publishZones);
TRACE_3("zone on object",_id,_obj,_domains);

_id
