#include "script_component.hpp"
/*
 * Author: JMSB
 * The custom channels in use, as the server last counted them
 * (FUNC(countChannels)) - the voice API's "channelUse" hook.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [used, of] - [] before the first count <ARRAY>
 *
 * Example:
 * [] call jmfsb_adapter_von_fnc_channelUse
 *
 * Public: No
 */

+(missionNamespace getVariable [QGVAR(channelUse), []])
