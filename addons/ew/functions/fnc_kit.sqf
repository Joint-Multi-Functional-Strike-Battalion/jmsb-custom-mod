#include "script_component.hpp"
/*
 * Author: JMSB
 * What EW kit a man has to hand - THE EQUIPMENT GATE (DESIGN_EW "ISR trait",
 * "EW hardware"):
 *
 *   receiver  the EW Receiver (DF), carried, or in the cargo of the vehicle
 *             he is in: dedicated DF (2 deg, every band) and anti-spoof GPS
 *   host      what his jammer radiates from: the vehicle he is in when an
 *             EW jammer module is in its cargo, objNull for no jammer. Never
 *             the man himself - there are no man packs (user, 2026-10-21)
 *   vehicle   whether the host is a vehicle
 *   isr       the DIVINER ISR trait (jmfsb_common_fnc_isISR): one DF class
 *             better, spot jamming, spoofing and decoys
 *
 * Reads gear only, so it answers on any machine.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * HASHMAP with receiver, host, vehicle, isr <HASHMAP>
 *
 * Example:
 * ([player] call jmfsb_ew_fnc_kit) get "host"
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

private _out = createHashMapFromArray [["receiver", false], ["host", objNull], ["vehicle", false], ["isr", false]];
if (isNull _unit || {!alive _unit}) exitWith {_out};

private _veh = objectParent _unit;
private _receiver = ITEM_RECEIVER in (items _unit)
    || {!isNull _veh && {ITEM_RECEIVER in (itemCargo _veh)}};

private _host = objNull;
if (!isNull _veh && {ITEM_JAMMER_PACK in (backpackCargo _veh)}) then {_host = _veh};

_out set ["receiver", _receiver];
_out set ["host", _host];
_out set ["vehicle", !isNull _host && _host isNotEqualTo _unit];
_out set ["isr", [_unit] call EFUNC(common,isISR)];
_out
