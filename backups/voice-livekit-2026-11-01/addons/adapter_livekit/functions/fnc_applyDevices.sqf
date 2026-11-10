#include "script_component.hpp"
/*
 * Author: YonV
 * Tells the extension which microphone and speakers to use - the player's
 * two settings (part of a device's name as Windows lists it; empty = the
 * Windows default). The extension opens them on its next connect, and when
 * a session is live at once off the game's thread ("reopening"; a failure
 * comes back as its "error" or "nomic" callback) (user, 2026-10-31: the echo came out of the
 * speakers, not the headset the game plays on). Called at settings init and
 * when either setting changes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The extension took it <BOOL>
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_applyDevices
 *
 * Public: No
 */

if (!hasInterface || GVAR(version) isEqualTo "") exitWith {false};

(["device", [GVAR(inputDevice), GVAR(outputDevice)]] call FUNC(ext)) params ["_result", "_ran"];
if (!_ran) exitWith {
    WARNING_1("voice devices: %1",_result);
    false
};
INFO_3("voice devices: microphone '%1', speakers '%2' -> %3",GVAR(inputDevice),GVAR(outputDevice),_result);
true
