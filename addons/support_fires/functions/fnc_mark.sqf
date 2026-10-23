#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts a mission's target on the map for the asset's side - Simplex's task
 * marker: an icon on the point with the asset's words, and the area shelled
 * or hunted as an outline when the mission has one. It stays until the
 * mission ends (FUNC(finish) calls FUNC(unmark)).
 *
 * Raised on the server as a JIP global event under one id per asset, so a
 * player joining mid-mission sees it, and a later mission of the same asset
 * replaces it. Each client draws it locally only when he is on the asset's
 * side (XEH_postInit).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position <ARRAY>
 * 2: Marker text <STRING>
 * 3: Area radius (m), 0 for none <NUMBER> (optional, default 0)
 *
 * Return Value: None
 *
 * Example:
 * [_logic, _pos, "THUNDER - FIRE MISSION", 100] call jmfsb_support_fires_fnc_mark
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_pos", [], [[]]], ["_text", "", [""]], ["_radius", 0, [0]]];

if (!isServer || {isNull _logic} || {_pos isEqualTo []}) exitWith {};

private _id = _logic getVariable [QGVAR(id), -1];
[QGVAR(mark), [_id, _logic getVariable [QGVAR(side), sideUnknown], _pos, _text, _radius], format ["%1_mark_%2", QUOTE(ADDON), _id]] call CBA_fnc_globalEventJIP;
