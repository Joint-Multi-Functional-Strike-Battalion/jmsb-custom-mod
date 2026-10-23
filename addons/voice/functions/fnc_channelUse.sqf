#include "script_component.hpp"
/*
 * Author: JMSB
 * How much of the engine's custom channels game voice is using - for the
 * devices' gauge (user, 2026-10-21). Game voice has ten custom channels in
 * all: C2, A2G and every live CALL take one each, and so does any the mission
 * made itself. Under TFAR / ACRE (no "channelUse" hook) there is nothing to
 * count.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [used, of], [] when not counted <ARRAY>
 *
 * Example:
 * ([] call jmfsb_voice_fnc_channelUse) params ["_used", "_of"]
 *
 * Public: Yes
 */

if (!GVAR(active)) exitWith {[]};
private _use = [] call HOOK("channelUse");
if (isNil "_use" || {!(_use isEqualType [])}) exitWith {[]};
_use
