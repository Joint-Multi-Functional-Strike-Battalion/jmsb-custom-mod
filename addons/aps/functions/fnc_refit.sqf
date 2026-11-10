#include "script_component.hpp"
/*
 * Author: YonV
 * Fits every vehicle again (server). Called when the tables change under a
 * running system - a JMSB - APS module arriving after the settings had
 * already armed it, with a tier or fit table of its own. Each vehicle's watch
 * is stopped and its fit forgotten; the next sweep, run at once, fits it to
 * the new tables. Holds the crews have set are kept - they are the crew's
 * word, not the table's.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

if (!isServer) exitWith {};

{
    private _veh = _x;
    private _h = _veh getVariable [QGVAR(pfh), -1];
    if (_h >= 0) then {
        [_h] call CBA_fnc_removePerFrameHandler;
        _veh setVariable [QGVAR(pfh), nil];
    };
    {
        _veh setVariable [_x, nil, true];
    } forEach [QGVAR(fit), QGVAR(rf), QGVAR(name), QGVAR(ammoL), QGVAR(ammoR), QGVAR(ammoMax), QGVAR(rfReady)];
} forEach GVAR(registered);

GVAR(registered) = [];
call FUNC(sweep);
