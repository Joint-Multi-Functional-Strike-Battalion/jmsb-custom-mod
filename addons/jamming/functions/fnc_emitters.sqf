#include "script_component.hpp"
/*
 * Author: JMSB
 * The live jam zones as emitters, for direction finding (jmfsb_ew): where each
 * one radiates from, how far it reaches, what it denies and whose it is. A
 * zone with an object radiates from the object; an abstract zone (a hack's
 * temporary field) from its point. The GPS sphere is space-based - it has no
 * emitter on the ground, only its uplink does - so an abstract GPS-only zone
 * is left out.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[id, object, position ASL, outer radius m, domains, owner tag], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_jamming_fnc_emitters
 *
 * Public: Yes
 */

private _out = [];
{
    if ((_x param [ZONE_TYPE, "jam"]) isNotEqualTo "jam") then {continue};
    private _obj = _x param [ZONE_OBJ, objNull];
    private _temp = _x param [ZONE_TEMP, false];
    if (!_temp && {isNull _obj || {!alive _obj}}) then {continue};
    private _model = _x param [ZONE_MODEL, createHashMap];
    private _domains = _model getOrDefault ["domains", DOM_DEFAULT];
    if (isNull _obj && {_domains isEqualTo [DOM_GPS]}) then {continue};
    _out pushBack [
        _x param [ZONE_ID, ""],
        _obj,
        [getPosASL _obj, _x param [ZONE_POS, [0, 0, 0]]] select (isNull _obj),
        _x param [ZONE_RFALL, 0],
        _domains,
        _model getOrDefault ["owner", ""]
    ];
} forEach (missionNamespace getVariable [QGVAR(jammers), []]);

_out
