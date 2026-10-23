#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: something that radiates but is not an RF node - a jammer another
 * addon prices as RF noise itself (the Drone40 Jammer), an APS burst, a
 * radar - so ES hears it, DFs it and classifies it like any emitter. Its
 * noise stays its owner's; this only makes it heard. It is dropped when its
 * object dies or is deleted; a vehicle with no fuel (a flat drone) is dark.
 *
 * Arguments:
 * 0: Object it radiates from <OBJECT>
 * 1: Bands <ARRAY of STRINGs>
 * 2: Transmitted power dBm (optional, default SITE_TX_DBM) <NUMBER>
 * 3: Intent, "jam" / "spoof" / "" (optional, default "jam") <STRING>
 * 4: Side (optional, default the object's) <SIDE>
 * 5: Id (optional, default generated) <STRING>
 *
 * Return Value:
 * Emitter id, "" when refused <STRING>
 *
 * Example:
 * [_drone, ["VHF", "UHF"], 37, "jam"] call jmfsb_ew_fnc_addEmitter
 *
 * Public: Yes
 */

params [
    ["_obj", objNull, [objNull]],
    ["_bands", [], [[]]],
    ["_dBm", SITE_TX_DBM, [0]],
    ["_intent", INTENT_JAM, [""]],
    ["_side", sideUnknown, [west]],
    ["_id", "", [""]]
];

if (!isServer || {isNull _obj} || {_bands isEqualTo []}) exitWith {""};

if (_id isEqualTo "") then {
    GVAR(nextExternal) = GVAR(nextExternal) + 1;
    _id = format ["ew_ext_%1", GVAR(nextExternal)];
};
if (_side isEqualTo sideUnknown) then {_side = side group _obj};

GVAR(external) set [_id, [_obj, _bands, _dBm, _intent, str _side]];
_id
