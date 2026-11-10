#include "script_component.hpp"

// A sound at a range, heard by whoever is near it.
[QGVAR(say), {
    params ["_source", "_sound"];
    if (!hasInterface || {isNull _source}) exitWith {};
    _source say3D _sound;
}] call CBA_fnc_addEventHandler;
