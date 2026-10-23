#include "script_component.hpp"

// ON TAC//SUPPORT AS A PROVIDER OF THE SUPPORT CORE, kind "air": CAS,
// transport, logistics drops and QRF insertion, one row per placed module.
// Registered on EVERY machine: the page is drawn on the client and reads its
// rows there. See addons/support/README.md for the contract.
[SUPPORT_KIND, createHashMapFromArray [
    ["assets", FUNC(assets)],
    ["task", FUNC(task)],
    ["sitrep", FUNC(sitrep)],
    ["available", FUNC(assetAvailable)],
    ["tasks", FUNC(tasks)],
    ["preview", FUNC(preview)],
    ["overlay", FUNC(overlay)],
    ["types", SUPPORT_TYPES]
]] call EFUNC(support,registerProvider);

// THE SERVER FLIES EVERYTHING. An order accepted on a client lands here.
if (isServer) then {
    [QGVAR(order), {_this call FUNC(order)}] call CBA_fnc_addEventHandler;
};

// AI OUT OF A HELICOPTER, WHERE THE MAN LIVES. unassignVehicle and moveOut
// only take effect on the unit's own machine, and a player's AI squadmates
// live on his client, not on the server that flies the transport.
[QGVAR(putOut), {
    params [["_unit", objNull, [objNull]]];
    unassignVehicle _unit;
    moveOut _unit;
}] call CBA_fnc_addEventHandler;

// A JUMP, WHERE THE MAN LIVES - a PARADROP puts the whole cabin out, players
// and a player's AI squadmates included, and moveOut and the canopy only
// take on the unit's own machine (FUNC(transportStep)).
[QGVAR(jumpOut), {
    params [["_unit", objNull, [objNull]], ["_veh", objNull, [objNull]]];
    [_unit, _veh] call FUNC(jump);
}] call CBA_fnc_addEventHandler;

if (!hasInterface) exitWith {};

// WHAT THE SIDE HEARS. The requester already has it as the support core's
// acknowledgement (FUNC(say)); everyone else on the side gets the same line
// on the notify rail, so a drop or a QRF is not something that silently
// happens somewhere.
[QGVAR(say), {
    params [["_side", sideUnknown, [west]], ["_text", "", [""]], ["_prio", "normal", [""]], ["_requester", objNull, [objNull]]];
    if (_side isNotEqualTo (side group player)) exitWith {};
    if (!isNull _requester && {player isEqualTo _requester}) exitWith {};
    ["SUPPORT", _text, _prio] call EFUNC(messaging,notify);
}] call CBA_fnc_addEventHandler;
