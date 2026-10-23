#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts a map back on the player. Momentary, not a tool: it moves the map and
 * leaves whatever tool is running exactly as it was.
 *
 * The vehicle when there is one - on a fast mover the man and the aircraft are
 * not in the same grid square by the time the map finishes moving. The zoom is
 * left where the player put it: this is CENTRE, not RESET VIEW.
 *
 * WHERE HIS GPS SAYS (jmfsb_ew_fnc_gpsHere, when EW is loaded): spoofed, the
 * map goes to the false fix; denied, it does not move and he is told there
 * is no fix.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [(findDisplay 12) displayCtrl 51] call jmfsb_maptools_fnc_centre
 *
 * Public: Yes
 */

params [["_map", controlNull, [controlNull]]];

if (isNull _map) exitWith {};

private _at = player;
if !(isNull objectParent player) then {_at = objectParent player};

private _pos = getPosATL _at;
if (!isNil QEFUNC(ew,gpsHere)) then {
    private _gps = [true] call EFUNC(ew,gpsHere);
    // if/then, not select: select would take the difference of an empty fix.
    _pos = if (_gps isEqualTo []) then {[]} else {_pos vectorAdd (_gps vectorDiff (getPosATL player))};
};
if (_pos isEqualTo []) exitWith {};

ctrlMapAnimClear _map;
_map ctrlMapAnimAdd [CENTRE_ANIM, ctrlMapScale _map, _pos];
ctrlMapAnimCommit _map;
