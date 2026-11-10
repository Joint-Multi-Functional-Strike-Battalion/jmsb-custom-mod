#include "script_component.hpp"
/*
 * Author: YonV
 * Wave 2: something comes to look.
 *
 * Out of that side's cache-limited ceiling, so raiding supply thins the
 * answer - which is the whole reason the caches exist.
 *
 * Arguments:
 * 0: Answering side <SIDE>
 * 1: Objective position <ARRAY>
 *
 * Return Value: None
 *
 * Public: No
 */

params ["_side", "_pos"];

if (isNil "jmfsb_uas_fnc_respondTo") exitWith {
    INFO("QRF drones: no UAS addon loaded");
};

private _sent = [_side, _pos] call jmfsb_uas_fnc_respondTo;
INFO_2("QRF drones: %1 sent=%2",_side,_sent);
