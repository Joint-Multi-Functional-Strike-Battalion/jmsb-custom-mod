#include "script_component.hpp"
/*
 * Author: JMSB
 * Sets off the crate's signal once it is on the ground - smoke, an IR
 * strobe, a chemlight or a flare, as the module or the requester chose - so
 * the section that asked for it can find it in the trees (Simplex attaches
 * its two signals on touchdown the same way). "" is no signal.
 *
 * Arguments:
 * 0: The crate <OBJECT>
 * 1: Signal class <STRING> (optional, default "" - none)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_crate, "SmokeShellBlue"] call jmfsb_support_air_fnc_markCrate
 *
 * Public: No
 */

// How long the crate has to reach the ground before nobody waits for it.
#define MARK_PATIENCE 300
// Height above the ground that counts as down.
#define MARK_DOWN 1

params [["_crate", objNull, [objNull]], ["_signal", "", [""]]];

if (isNull _crate || _signal isEqualTo "") exitWith {};

[
    {
        params ["_crate"];
        isNull _crate || {isNull attachedTo _crate && {((getPos _crate) select 2) < MARK_DOWN}}
    },
    {
        params ["_crate", "_signal"];
        if (isNull _crate) exitWith {};
        createVehicle [_signal, getPosATL _crate, [], 0, "CAN_COLLIDE"];
        INFO_2("crate '%1' down at %2",typeOf _crate,mapGridPosition _crate);
    },
    [_crate, _signal],
    MARK_PATIENCE
] call CBA_fnc_waitUntilAndExecute;
