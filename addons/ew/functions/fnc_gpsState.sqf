#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: this man's GPS (DESIGN_RF "rf_gpsState"), from his slice and the
 * jamming addon's denial:
 *
 *   GOOD     the true position
 *   SPOOFED  an unprotected set walked off by [dx, dy] (FUNC(spoof)); the man
 *            is not told - his GPS simply says he is somewhere else
 *   SUSPECT  an anti-spoof set (the EW Receiver) in a spoofer's field: the fix
 *            is held and flagged
 *   NO FIX   denied - the jamming addon's GPS field has taken the lock
 *            (jmfsb_jamming_gpsDenied, the edge it hides the GPS display on).
 *            The position is still computed; a reader must not show it.
 *
 * For consumers that show a GPS position - the own BFT dot, the grid
 * readout, CUR LOC in reports, drone navigation - so they follow the false
 * fix. Other men: FUNC(gpsOf). Display text: FUNC(gpsGrid), FUNC(gpsHere).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [state, [dx, dy] m, GPS position ASL] <ARRAY>
 *
 * Example:
 * ([] call jmfsb_ew_fnc_gpsState) params ["_state", "_offset", "_pos"]
 *
 * Public: Yes
 */

(GVAR(mine) param [6, [GPS_GOOD, [0, 0]]]) params [["_state", GPS_GOOD], ["_offset", [0, 0]]];
if (missionNamespace getVariable [QEGVAR(jamming,gpsDenied), false]) then {_state = GPS_NOFIX};
private _pos = (getPosASL player) vectorAdd [_offset select 0, _offset select 1, 0];
[_state, _offset, _pos]
