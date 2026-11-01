#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "selfTest" (jmfsb_voice_fnc_selfTest under TFAR): logs to the
 * RPT what this adapter reads off TFAR - each set's node, the plan's nets as
 * TFAR sets, the voice API's view (nets, rows, active net), who is heard
 * keying, and the two range levers.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_tfar_fnc_selfTest
 *
 * Public: No
 */

INFO_2("selfTest tfar: %1 sets, plan %2",count GVAR(sent),[] call FUNC(planNets));
{
    INFO_2("selfTest tfar: node %1 %2",_x,_y);
} forEach GVAR(sent);
INFO_3("selfTest tfar: active %1 (picked set %2), nets %3",GVAR(current),GVAR(activeKind),GVAR(nets));
{
    INFO_1("selfTest tfar: row %1",_x);
} forEach GVAR(rows);
INFO_2("selfTest tfar: heard %1, keyed %2",values GVAR(heard),GVAR(txNet));
private _unit = missionNamespace getVariable ["TFAR_currentUnit", player];
private _send = _unit getVariable [TF_SEND_VAR, QUALITY_FULL];
private _receive = _unit getVariable [TF_RECV_VAR, QUALITY_FULL];
INFO_2("selfTest tfar: send lever %1, receive lever %2",_send,_receive);
