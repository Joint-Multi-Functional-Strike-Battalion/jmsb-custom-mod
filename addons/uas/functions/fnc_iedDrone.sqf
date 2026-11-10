#include "script_component.hpp"
/*
 * Author: YonV
 * Arms an IED Pelican: a cargo quad with a charge where the crate was.
 *
 * TWO TRIGGERS, ONE BANG. Drongo's Drone Tweaks flies the thing - it is
 * registered with DDT as an FPV in XEH_postInit, so an AI operator deploys
 * it and DDT guides it into whatever it finds - but DDT only ever crashes an
 * airframe; the mods whose FPVs it flies explode on their own. This one has
 * no warhead in its config, so:
 *
 *   PROXIMITY  - a hostile inside UAS_IED_RADIUS sets it off. That is the
 *                "prox explosive" the brief asked for, and it is what makes
 *                the drone lethal at the end of a DDT run, where the flight
 *                model rarely gets a clean hit.
 *   KILLED     - shot down, crashed, or set off by the above: the charge goes
 *                either way. Nothing gets to pick the drone up and defuse it.
 *
 * ARMS LATE AND NEVER ON FRIENDS. The proximity check ignores the drone's own
 * side and does not start until UAS_IED_ARM_DELAY after spawn, so a bird
 * assembled at the operator's feet does not take the operator with it.
 *
 * SERVER ONLY. The drone is created on the server - by DDT's deploy, by
 * ALiVE, by Zeus - and stays local there; a Killed handler on the machine
 * it is local to is the one that fires.
 *
 * Arguments:
 * 0: The drone <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_drone] call jmfsb_uas_fnc_iedDrone
 */

params [["_drone", objNull, [objNull]]];
if (!isServer || {isNull _drone}) exitWith {};
if (_drone getVariable [QGVAR(iedArmed), false]) exitWith {};
_drone setVariable [QGVAR(iedArmed), true];

// THE CHARGE. A demolition block's worth: enough for a squad in the open or
// a soft vehicle, not enough to be an artillery round - this is a quad, and
// what it lifts is what it carries.
_drone addEventHandler ["Killed", {
    params ["_d"];
    private _pos = getPosATL _d;
    private _charge = "DemoCharge_Remote_Ammo" createVehicle _pos;
    _charge setDamage 1;
    "HelicopterExploSmall" createVehicle _pos;
}];

// THE FUZE. A per-frame handler at UAS_IED_TICK, started once the arming
// delay is up and removed with the drone.
[{
    params ["_d"];
    if (isNull _d || {!alive _d}) exitWith {};
    [{
        params ["_args", "_id"];
        _args params ["_d"];
        if (isNull _d || {!alive _d}) exitWith {[_id] call CBA_fnc_removePerFrameHandler};
        private _side = side _d;
        private _near = (_d nearEntities [["CAManBase", "LandVehicle", "Air", "Ship"], UAS_IED_RADIUS]) select {
            alive _x
            && _x isNotEqualTo _d
            && {(side _x) getFriend _side < 0.6}
        };
        if (_near isNotEqualTo []) then {
            [_id] call CBA_fnc_removePerFrameHandler;
            _d setDamage 1;
        };
    }, UAS_IED_TICK, [_d]] call CBA_fnc_addPerFrameHandler;
}, [_drone], UAS_IED_ARM_DELAY] call CBA_fnc_waitAndExecute;
