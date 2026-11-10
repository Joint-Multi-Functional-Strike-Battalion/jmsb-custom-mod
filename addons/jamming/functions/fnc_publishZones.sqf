#include "script_component.hpp"
/*
 * Author: YonV
 * Sends the zone registry to every client. ONCE PER BATCH, never per zone.
 *
 * The registry is one fat array and clients need all of it, so publishing is
 * not free: each entry carries an object, a position and a falloff model.
 * Publishing inside the per-zone spawn made a batch of n zones send
 * 1+2+...+n entries in a single frame - a run that placed 156 objective
 * jammers pushed over twelve thousand entries through the server's main
 * thread at once, which is exactly the kind of spike that reads as the
 * server locking up rather than as a slow script.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Example:
 * [] call jmfsb_jamming_fnc_publishZones
 */

if (!isServer) exitWith {};
if (isNil QGVAR(jammers)) then { GVAR(jammers) = [] };

missionNamespace setVariable [QGVAR(jammers), GVAR(jammers), true];
