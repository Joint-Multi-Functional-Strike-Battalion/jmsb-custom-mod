#include "script_component.hpp"
/*
 * Author: JMSB
 * Rebuilds the band table from the band settings: one entry per band of
 * [path-loss exponent, loss at 1 m dB, noise floor dBm]. Called at preInit and
 * from every band setting's change script, so the link budget reads one map
 * instead of twelve globals per pair.
 *
 * A setting not initialised yet reads as its default; the last setting to
 * initialise rebuilds the table with everything in place.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_rf_fnc_updateBands
 *
 * Public: No
 */

GVAR(bands) = createHashMapFromArray [
    ["VHF", [
        missionNamespace getVariable [QGVAR(vhfExp), VHF_EXP],
        missionNamespace getVariable [QGVAR(vhfRef), VHF_REF],
        missionNamespace getVariable [QGVAR(vhfFloor), VHF_FLOOR]
    ]],
    ["UHF", [
        missionNamespace getVariable [QGVAR(uhfExp), UHF_EXP],
        missionNamespace getVariable [QGVAR(uhfRef), UHF_REF],
        missionNamespace getVariable [QGVAR(uhfFloor), UHF_FLOOR]
    ]],
    ["SAT", [
        missionNamespace getVariable [QGVAR(satExp), SAT_EXP],
        missionNamespace getVariable [QGVAR(satRef), SAT_REF],
        missionNamespace getVariable [QGVAR(satFloor), SAT_FLOOR]
    ]],
    ["VIDEO", [
        missionNamespace getVariable [QGVAR(videoExp), VIDEO_EXP],
        missionNamespace getVariable [QGVAR(videoRef), VIDEO_REF],
        missionNamespace getVariable [QGVAR(videoFloor), VIDEO_FLOOR]
    ]]
];
// a band the table has not built yet has no edges
GVAR(edgeCache) = createHashMap;
