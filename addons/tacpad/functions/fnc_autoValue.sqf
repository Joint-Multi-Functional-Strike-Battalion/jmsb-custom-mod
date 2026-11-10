#include "script_component.hpp"
/*
 * Author: YonV
 * What one autofill source answers now (report-card review, user 2026-11-02,
 * decision 5). A field's autoFill names the source; one that takes an
 * argument names it after AUTO_SEP.
 *
 *   vehicle                       FUNC(autoVehicle)
 *   vehicleDamage, vehicleFuel    FUNC(autoDamage), FUNC(autoFuel)
 *   wind                          FUNC(autoWind)
 *   squadAce:<A, C or E>          FUNC(autoSquadAce)
 *   threadAnchor                  FUNC(autoAnchor)
 *
 *   ipHeading, ipDistance,        FUNC(autoCas) - the CAS REQUEST's true
 *   targetElevation, friendlies   9-line (2026-11-09): lines 2-4 and 8
 *
 * Arguments:
 * 0: The field's autoFill <STRING>
 * 1: The thread being answered, "" for a new message <STRING>
 *
 * Return Value:
 * The value - a word, a text, a number or a position; "" or [] for none <ANY>
 *
 * Example:
 * ["squadAce:A", ""] call jmfsb_tacpad_fnc_autoValue
 *
 * Public: No
 */

params [["_source", "", [""]], ["_threadId", "", [""]]];

private _parts = _source splitString AUTO_SEP;

switch (_parts param [0, ""]) do {
    case AUTO_VEHICLE: {[] call FUNC(autoVehicle)};
    case AUTO_DAMAGE: {[] call FUNC(autoDamage)};
    case AUTO_FUEL: {[] call FUNC(autoFuel)};
    case AUTO_WIND: {[] call FUNC(autoWind)};
    case AUTO_SQUAD_ACE: {[_parts param [1, ""]] call FUNC(autoSquadAce)};
    case AUTO_ANCHOR: {[_threadId] call FUNC(autoAnchor)};
    case AUTO_IP_HEADING;
    case AUTO_IP_DISTANCE;
    case AUTO_TARGET_ELEVATION;
    case AUTO_FRIENDLIES: {[_parts select 0] call FUNC(autoCas)};
    default {""};
}
