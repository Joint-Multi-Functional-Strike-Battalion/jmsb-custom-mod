#include "script_component.hpp"

// ---- every machine: the firing side of detection ---------------------------
// Every shot of every unit passes through here, so an ignored type must cost
// one hashmap lookup (FUNC(fired)). Only the machine where the shooter is
// LOCAL goes further - it owns the round, so it is the one that can delete it.
["AllVehicles", "fired", LINKFUNC(fired)] call CBA_fnc_addClassEventHandler;

// The server asks the firing machine to kill a round it owns (FUNC(resolve)).
[QGVAR(kill), LINKFUNC(kill)] call CBA_fnc_addEventHandler;
// The server asks the gunner's machine to fire (FUNC(assign)) when the gunner
// is not the server's - a headless client's crew.
[QGVAR(fire), LINKFUNC(fire)] call CBA_fnc_addEventHandler;

if (!isServer) exitWith {};

// A fired round reported by its firing machine (FUNC(shot)) - the server's
// own shots arrive here too, as a local event.
[QGVAR(threat), LINKFUNC(threat)] call CBA_fnc_addEventHandler;

// jmfsb_airdefence's batteries and AA bases: one alarm area per battery,
// claimed from whatever automatic area their pieces were put in at creation.
[QEGVAR(airdefence,batteryUp), {
    params [["_vehicles", [], [[]]], ["_side", sideUnknown, [sideUnknown]], ["_pos", [], [[]]]];
    private _key = format ["battery_%1_%2", _side, mapGridPosition ASLToAGL _pos];
    {
        [_x, _key, -1, -1, true] call FUNC(register);
    } forEach _vehicles;
}] call CBA_fnc_addEventHandler;

["adsite", "air defence intercept: units, threats in the air, last pass ms", {
    [] call FUNC(status)
}] call EFUNC(common,addDebugCommand);
