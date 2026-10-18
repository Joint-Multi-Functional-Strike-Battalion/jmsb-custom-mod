#include "script_component.hpp"
/*
 * Author: JMSB
 * Plans and builds every commander's air defence, once.
 *
 * Called by FUNC(moduleController) when ALiVE is up - never on its own. The
 * one tick this addon keeps is the rearm loop below; everything else is built
 * once and left standing.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Example:
 * [] call jmfsb_airdefence_fnc_start
 */

if (!isServer) exitWith {};

[] call FUNC(plan);

// The rearm loop - the one tick this addon keeps (FUNC(rearmLoop), started
// once whether this or an AA Base module asks first).
[] call FUNC(rearmLoop);
