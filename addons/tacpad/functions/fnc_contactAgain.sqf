#include "script_component.hpp"
/*
 * Author: YonV
 * A sign of contact on the watched TIC (FUNC(contactArm)): its time is now,
 * a CONTACT OVER? already said is taken back - contact has resumed, and the
 * prompt is armed again for when it goes quiet - and a quiet check is queued
 * when none is (FUNC(contactCheck)).
 *
 * The group's event handlers stamp the time themselves and call this only
 * while CONTACT OVER? is up, so a firefight costs one assignment per shot.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_contactAgain
 *
 * Public: No
 */

GVAR(contactLast) = CBA_missionTime;

if (GVAR(contactThread) isEqualTo "") exitWith {};

if (GVAR(contactPrompted)) then {
    GVAR(contactPrompted) = false;
    if (!isNull (uiNamespace getVariable [QGVAR(reader), displayNull])) then {
        [QGVAR(readerDraw), {[] call FUNC(readerDraw)}] call FUNC(nextFrameOnce);
    };
};

if (GVAR(contactPending)) exitWith {};
GVAR(contactPending) = true;
[{[] call FUNC(contactCheck)}, [], CONTACT_QUIET_S] call CBA_fnc_waitAndExecute;
