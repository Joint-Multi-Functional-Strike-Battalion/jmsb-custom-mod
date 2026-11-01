#include "script_component.hpp"
/*
 * Author: JMSB
 * How long a hack of this kind runs - each kind on its own clock. One answer
 * for the tablet that runs the bar (FUNC(tabletAction)) and the server that
 * checks the hack really ran its course (FUNC(srvHackComplete), review S7).
 *
 * Arguments:
 * 0: Kind, "tower" | "drone" | "wreck" | "unit" <STRING>
 *
 * Return Value:
 * Seconds, at least 1 <NUMBER>
 *
 * Example:
 * ["tower"] call jmfsb_hacking_fnc_hackDuration
 *
 * Public: No
 */

params [["_kind", "", [""]]];

private _time = switch (_kind) do {
    case "unit": {missionNamespace getVariable [QGVAR(rh_hack_time), RH_TIME_DEF]};
    case "drone": {HACK_DURATION};
    // A wreck has no security left to beat, only a card to copy.
    case "wreck": {HACK_WRECK_DURATION};
    default {[QGVAR(cfg_hack_time)] call FUNC(hackSetting)};
};

_time max 1
