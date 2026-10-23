#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: an RTO net's name as typed, checked and turned into its id. The id
 * IS the name, upper-cased and trimmed - it is what the chip shows and what
 * FUNC(netKind) and the adapter's channel key go by - so it must be short,
 * plain, and no name anything else already answers to: the fixed nets, the
 * engine channels, the TEAM and CALL prefixes, any plan net, any RTO net.
 *
 * Arguments:
 * 0: Name as typed <STRING>
 *
 * Return Value:
 * 0: Id, "" when refused <STRING>
 * 1: Reason when refused (REASON_BAD_NAME, REASON_TAKEN), else "" <STRING>
 *
 * Example:
 * ["recon 2"] call jmfsb_voice_fnc_customValid
 *
 * Public: No
 */

params [["_name", "", [""]]];

private _id = toUpper trim _name;
if (count _id < CUSTOM_NAME_MIN || count _id > CUSTOM_NAME_MAX) exitWith {["", REASON_BAD_NAME]};
private _allowed = toArray CUSTOM_NAME_CHARS;
if (((toArray _id) findIf {!(_x in _allowed)}) >= 0) exitWith {["", REASON_BAD_NAME]};
if (_id in CUSTOM_RESERVED) exitWith {["", REASON_BAD_NAME]};
if ((CUSTOM_RESERVED_PREFIXES findIf {(_id find _x) isEqualTo 0}) >= 0) exitWith {["", REASON_BAD_NAME]};
if (_id in GVAR(planKinds) || {_id in GVAR(customNets)}) exitWith {["", REASON_TAKEN]};

[_id, ""]
