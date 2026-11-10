#include "script_component.hpp"
/*
 * Author: YonV
 * Server: draws one intel product on every screen of the side it is for, by
 * remoteExec to FUNC(renderProduct), which takes it only from the server
 * (review S7). The side filter stays on the receiving client.
 *
 * Arguments:
 * The payload FUNC(renderProduct) takes, kind first, side last <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["circle", _id, _centre, _radius, "", "", "AA T1", west] call jmfsb_hacking_fnc_sendProduct
 *
 * Public: Yes
 */

if (!isServer) exitWith {
    WARNING_1("sendProduct: called off the server - %1",_this);
};

_this remoteExecCall [QFUNC(renderProduct), 0];
