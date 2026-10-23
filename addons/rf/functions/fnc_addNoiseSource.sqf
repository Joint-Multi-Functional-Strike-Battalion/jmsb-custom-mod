#include "script_component.hpp"
/*
 * Author: JMSB
 * THE NOISE-SOURCE HOOK. EW registers its jammers here; RF never knows what
 * they are. The code is called on the server for every receiver the budget
 * prices, with [position ASL, band, net id], and returns the interference it
 * adds there as [[dBm at the receiver, spreadApplies], ...] (an empty array
 * for none). It runs per receiver per net per tick, so it must be cheap.
 *
 * Arguments:
 * 0: Noise source <CODE>
 *
 * Return Value:
 * Hook index <NUMBER>
 *
 * Example:
 * [{params ["_pos", "_band"]; []}] call jmfsb_rf_fnc_addNoiseSource
 *
 * Public: Yes
 */

params [["_code", {[]}, [{}]]];

GVAR(noiseSources) pushBack _code
