#include "script_component.hpp"
/*
 * Author: YonV
 * The side's own cargo aircraft (DEFAULT_AIRCRAFT): what a JMSB - Jump
 * Aircraft module with no class flies (FUNC(moduleJump)), and the side's own
 * jump aircraft when no module of the side is placed (FUNC(asset)). The Jump
 * aircraft setting is retired (user, 2026-11-02: "Jump aircraft module" -
 * which aircraft is the module's, never a setting's). Not checked here: the
 * caller asks isClass.
 *
 * Arguments:
 * 0: Side <SIDE>
 *
 * Return Value:
 * Class name <STRING>
 *
 * Example:
 * [west] call jmfsb_jumpmaster_fnc_aircraftClass
 *
 * Public: No
 */

params [["_side", west, [west]]];

DEFAULT_AIRCRAFT select ((JUMP_SIDES find _side) max 0)
