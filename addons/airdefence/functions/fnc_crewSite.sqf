#include "script_component.hpp"
/*
 * Author: JMSB
 * Crews a site's hardware, keeps it out of ALiVE and announces it to adsite.
 *
 * Shared by FUNC(buildBattery) and FUNC(moduleAABase) - the one way a piece of
 * jmfsb air defence gets a crew, so the drone-turret lesson below is learned
 * once rather than once per builder.
 *
 * Arguments:
 * 0: The site's hardware <ARRAY of OBJECT>
 * 1: Owning side <SIDE>
 * 2: The site's centre, AGL <ARRAY>
 * 3: Man classes for manned statics <ARRAY>
 *
 * Return Value: None
 *
 * Example:
 * [_made, east, _pos, _kinds] call jmfsb_airdefence_fnc_crewSite
 *
 * Public: No
 */

params [["_made", [], [[]]], ["_side", sideUnknown, [sideUnknown]],
        ["_pos", [], [[]]], ["_kinds", [], [[]]]];

// Crew, then profile. An empty static never fires - and the crew DIFFERS BY
// KIND. The vanilla SAM and radar systems are AUTONOMOUS DRONE TURRETS
// (isUav): createVehicleCrew seats their own UAV AI, and that AI must STAY
// IN ITS OWN GROUP - joining it to an infantry group is what switched the
// autonomous systems off and left "batteries without crew". Only manned
// statics get men, and only their crews join the site's group.
private _grp = createGroup [_side, true];
{
    createVehicleCrew _x;
} forEach _made;

// A frame later: createVehicleCrew's units are not queryable in the same frame,
// and profiling a crewless vehicle hands ALiVE nothing to virtualise.
[{
    params ["_made", "_grp", "_side", "_pos", "_kinds"];

    private _live = _made select {!isNull _x};
    if (_live isEqualTo []) exitWith {};

    // Crews are only queryable here, a frame on. A DRONE turret (isUav) that
    // is still empty gets another createVehicleCrew - its own AI crewman is
    // the only thing that can run it, and a soldier pushed into a UAV seat is
    // exactly the wrong fix. A MANNED static that is still empty gets a man:
    // the faction's own when the site has any, the side's plain soldier
    // otherwise. Drone crews stay in their own groups; only men join the
    // site's group.
    private _crewed = 0;
    {
        private _isDrone = getNumber (configOf _x >> "isUav") > 0;
        if ((crew _x) isEqualTo []) then {
            if (_isDrone) then {
                createVehicleCrew _x;
            } else {
                private _man = if (_kinds isNotEqualTo []) then {selectRandom _kinds} else {
                    switch (_side) do {
                        case west: {"B_Soldier_F"};
                        case independent: {"I_Soldier_F"};
                        default {"O_Soldier_F"};
                    }
                };
                private _g = _grp createUnit [_man, getPos _x, [], 0, "CAN_COLLIDE"];
                _g moveInGunner _x;
            };
        };
        if (!_isDrone) then { (crew _x) joinSilent _grp };
        if ((crew _x) isNotEqualTo []) then { _crewed = _crewed + 1 };
    } forEach _live;
    INFO_3("battery for %1: %2 of %3 pieces crewed",_side,_crewed,count _live);

    // NEVER OFFERED TO THE PROFILER. THIS IS THE "AA SITE WITH NO AI".
    //
    // The log said "4 of 4 pieces crewed" and then "would not profile - it
    // stays live", and the site stood there empty anyway. That warning was
    // reading an empty return as "nothing happened", which is the same
    // mistake that was eating the drones: ALiVE's runtime profiler
    // does deleteVehicle to what it is handed unless every unit is on ALiVE's
    // own blacklist. A profile REPLACES the object - that is what
    // virtualisation is. Static air defence has nowhere to walk to and no
    // reason to be a record, so it is never handed over.
    //
    // ALiVE's own opt-out, asked for through the adapter - the variable is
    // ALiVE's name and this addon is not allowed to know it. Hardware, crews
    // and their groups, so any OTHER ALiVE pass over the map leaves the site
    // alone too; without it, "it stays live" was a claim nothing had actually
    // told ALiVE about.
    {[_x] call EFUNC(adapter_alive,profileIgnore)} forEach _live;
    [_grp] call EFUNC(adapter_alive,profileIgnore);

    INFO_2("battery up for %1 at %2",_side,mapGridPosition _pos);
    // jmfsb_adsite files its pieces into one alarm area as intercept units. A
    // local event - adsite listens on the server, where this runs.
    [QGVAR(batteryUp), [_live, _side, AGLToASL _pos]] call CBA_fnc_localEvent;
}, [_made, _grp, _side, _pos, _kinds]] call CBA_fnc_execNextFrame;
