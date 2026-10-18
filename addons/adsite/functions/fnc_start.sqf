#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Starts the one engagement PFH if it is not running. It runs only while a
 * threat is in the air - FUNC(tick) removes it when the queue empties - so an
 * idle server carries no handler of this addon's at all.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Example:
 * [] call jmfsb_adsite_fnc_start
 *
 * Public: No
 */

if (GVAR(pfh) >= 0) exitWith {};
GVAR(pfh) = [LINKFUNC(tick), ADS_TICK, []] call CBA_fnc_addPerFrameHandler;
