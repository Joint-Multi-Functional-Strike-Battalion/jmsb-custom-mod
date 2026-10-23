#include "script_component.hpp"
/*
 * Author: JMSB
 * The asset types and tasks the "alive" support provider answers, in the
 * support core's type-declaration shape (addons/support/README.md):
 *
 *   [type, label, one, many, order, [[token, label, meta, guidance], ...]]
 *
 * The tokens are what FUNC(supportTask) turns into NEO's own task arrays, and
 * the words are the ones TAC//SUPPORT has always shown for them - moved out of
 * the screen, which no longer knows any asset kind's tasks.
 *
 * None of these tasks declares steppers or a point requirement: ALiVE's
 * parameters (radius, altitude, ROE, speed, ordnance, rounds, dispersion,
 * guns) are the screen's legacy per-type layout, kept as it was.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Type declarations <ARRAY>
 *
 * Example:
 * call jmfsb_adapter_alive_fnc_supportTypes
 *
 * Public: No
 */

[
    ["transport", "TRANSPORT", "AIRFRAME", "AIRFRAMES", SUPPORT_ORDER_TRANSPORT, [
        ["PICKUP", "PICKUP", "", "Unit moves to the point and waits for smoke and confirm"],
        ["LAND", "LAND", "", "Unit will move to coordinates and land at its discretion"],
        ["MOVE", "MOVE", "", "Unit repositions to the point and waits"],
        ["CIRCLE", "CIRCLE", "", "Unit orbits the point until told otherwise"]
    ]],
    ["cas", "CAS", "AIRFRAME", "AIRFRAMES", SUPPORT_ORDER_CAS, [
        ["SAD", "SAD", "SEEK & DESTROY", "Unit will move to location, provide close air support and engage all painted targets"],
        ["LOITER", "LOITER", "", "Unit holds overhead the task point"],
        ["ATTACK RUN", "ATTACK RUN", "", "Unit makes attack runs on the task point"]
    ]],
    ["arty", "ARTILLERY", "BATTERY", "BATTERIES", SUPPORT_ORDER_ARTY, [
        ["FIRE MISSION", "FIRE MISSION", "", "Battery puts rounds on the task point, rapid rate"]
    ]]
]
