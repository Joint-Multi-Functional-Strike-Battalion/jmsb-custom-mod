#include "script_component.hpp"
/*
 * Author: JMSB
 * One module as one support-page row, in the neutral shape the page already
 * reads - see addons/support/README.md for the contract.
 *
 *   [id, type, callsign, platform, status, ordnance, guns, vehicle, plan]
 *
 * THE SHAPE IS THE SUPPORT CORE'S BECAUSE THE PAGE IS ALREADY WRITTEN. A CAS
 * provider that invented its own row would have needed a second renderer
 * beside the first, and the two would have drifted the first time a column
 * moved. The guns column is artillery's and stays empty here, exactly as
 * ALiVE's own air rows leave it.
 *
 * ORDNANCE IS THE AIRFRAME'S OWN STORES. The column that carries a battery's
 * shell types carries this airframe's - GBU-12, Scalpel, the cannon belt, by
 * name and with the rounds left on them - because a man calling a strike knows
 * what his drone is hung with and asks for THAT, not for a category. AUTO
 * leads the list and stays the default. See FUNC(stores) for the read and
 * FUNC(task) for the index that comes back.
 *
 * THE ID CARRIES THE PROVIDER'S KIND. "cas:3" routes back to this addon and to
 * entity 3; ALiVE's ids are "alive:cas:0" and cannot collide.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The row, [] when the logic is gone <ARRAY>
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[]};

([_logic] call FUNC(available)) params ["", "_status"];

// AUTO FIRST, ALWAYS, so index 0 means the same thing over every airframe on
// the board - and so a section that wants a strike and does not care can take
// the first entry without reading the rest.
private _ordnance = ["AUTO"] + (([_logic getVariable [QGVAR(cls), ""]] call FUNC(stores)) apply {_x select 1});

[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    "cas",
    _logic getVariable [QGVAR(callsign), "CAS"],
    getText (configFile >> "CfgVehicles" >> (_logic getVariable [QGVAR(cls), ""]) >> "displayName"),
    _status,
    _ordnance,
    0,
    // The airframe while it is out, and the run it is flying - the board's
    // map draws both (support core README, row fields 7 and 8).
    _logic getVariable [QGVAR(vehicle), objNull],
    _logic getVariable [QGVAR(plan), []]
]
