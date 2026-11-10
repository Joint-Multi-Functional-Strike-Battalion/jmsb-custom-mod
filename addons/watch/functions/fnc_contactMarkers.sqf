#include "script_component.hpp"
/*
 * Author: YonV
 * The map track (design recon.hud "box on contact + map track"): one local map
 * marker per contact this player sees - solid where it is, hollow at its last
 * known position - kept to the list once a second, gone with it. On every map
 * this machine draws, the tablet's included. No goggles needed.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_watch_fnc_contactMarkers
 *
 * Public: No
 */

private _want = [];
{
    _x params ["_obj", "_kind", "", "", "_pos", "_seen"];
    private _how = [_x] call FUNC(contactSeen);
    if (_how isEqualTo 0) then {continue};
    private _name = format ["%1_%2", QGVAR(track), hashValue _obj];
    _want pushBack _name;
    if !(_name in GVAR(markers)) then {
        createMarkerLocal [_name, ASLToAGL _pos];
        GVAR(markers) pushBack _name;
    };
    _name setMarkerPosLocal (ASLToAGL _pos);
    _name setMarkerTypeLocal ([MARKER_LOST, MARKER_SEEN] select (_how isEqualTo 2));
    _name setMarkerColorLocal ([MARKER_RECON, MARKER_THREAT] select (_kind isEqualTo "threat"));
    _name setMarkerTextLocal ([[_obj, _kind] call FUNC(contactName), format ["%1 (%2)", [_obj, _kind] call FUNC(contactName), [serverTime - _seen, "MM:SS"] call BIS_fnc_secondsToString]] select (_how isEqualTo 1));
} forEach GVAR(contactList);

{deleteMarkerLocal _x} forEach (GVAR(markers) - _want);
GVAR(markers) = _want;
