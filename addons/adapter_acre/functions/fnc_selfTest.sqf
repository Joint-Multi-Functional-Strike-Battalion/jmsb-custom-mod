#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "selfTest" (jmfsb_voice_fnc_selfTest under ACRE): logs to the
 * RPT each radio he carries with its base class, channel and net, the voice
 * API's view (nets, rows, the net in hand), who is heard on a radio and his
 * own transmission's net.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_acre_fnc_selfTest
 *
 * Public: No
 */

if (isNil "acre_api_fnc_getCurrentRadioList") exitWith {WARNING("selfTest acre: no ACRE API")};

{
    INFO_3("selfTest acre: radio %1 (%2) net %3",_x,[_x] call acre_api_fnc_getBaseRadio,[_x] call FUNC(radioNet));
} forEach ([] call acre_api_fnc_getCurrentRadioList);
INFO_2("selfTest acre: in hand %1, nets %2",GVAR(current),GVAR(nets));
{
    INFO_1("selfTest acre: row %1",_x);
} forEach GVAR(rows);
INFO_2("selfTest acre: heard %1, transmitting on %2",values GVAR(heard),GVAR(txNet));
