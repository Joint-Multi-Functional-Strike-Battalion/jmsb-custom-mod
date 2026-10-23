#include "script_component.hpp"
/*
 * Author: JMSB
 * The asset types provider "fires" declares to the support core:
 *
 *   [type, label, one, many, order, tasks]
 *
 * Artillery is the shared "arty" type, so a battery of ours - every one of
 * them virtual - lists beside any other provider's guns. Each task list here is the generic one; once an
 * asset is picked FUNC(tasks) answers with its own.
 *
 * Arguments: None
 *
 * Return Value:
 * Type declarations <ARRAY>
 *
 * Example:
 * call jmfsb_support_fires_fnc_typeList
 *
 * Public: No
 */

[
    [TYPE_ARTY, "ARTILLERY", "BATTERY", "BATTERIES", ORDER_ARTY, [TYPE_ARTY] call FUNC(taskDecls)],
    [TYPE_CRUISE, "CRUISE MISSILES", "LAUNCHER", "LAUNCHERS", ORDER_CRUISE, [TYPE_CRUISE] call FUNC(taskDecls)],
    [TYPE_LOITER, "LOITERING MUNITIONS", "SITE", "SITES", ORDER_LOITER, [TYPE_LOITER] call FUNC(taskDecls)]
]
