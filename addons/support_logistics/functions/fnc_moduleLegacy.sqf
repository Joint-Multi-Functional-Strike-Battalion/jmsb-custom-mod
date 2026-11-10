#include "script_component.hpp"
/*
 * Author: YonV
 * Reads one old JMSB - Logistics Drop module (support_air until 2026-11-01)
 * into a JMSB - Logistics asset, so a mission that placed it still has its
 * drop on TAC//SUPPORT (user: keep existing missions working).
 *
 * THE OLD MODULE IN THE NEW ONE'S TERMS. Most of its attributes already have
 * the new module's names and meanings - aircraft, callsign, crate, PAC lists
 * and counts, drop height, delay, cooldown and its start, respawn, signal -
 * and are read as they are. The two that are not:
 *   Method      PARACHUTE is AIRDROP, SLING is SLING LOAD; one of them, and
 *               a sling the aircraft cannot fly falls back to the airdrop
 *               (FUNC(moduleLogistics)), as it always did
 *   Drops       Respawns, one fewer, since 2026-11-02 - replacements for
 *               aircraft lost (0, unlimited, is Respawns -1)
 * and what it never had is what it always did: one crate per drop, flown
 * from the module, one helicopter, no item cooldown. Its
 * CONTENTS choice is the catalog's ITEM now - each load is a crate in it.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, [], true] call jmfsb_support_logistics_fnc_moduleLegacy
 *
 * Public: No
 */

// What the old Logistics Drop did, as the new module's values.
#define LEGACY_METHOD_SLING 1
#define LEGACY_CAPACITY     1
#define LEGACY_ITEM_COOLDOWN 0
// The old Drops attribute's own default.
#define LEGACY_DROPS        3

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic} || {!isServer}) exitWith {};

private _sling = (_logic getVariable ["method", 0]) isEqualTo LEGACY_METHOD_SLING;
_logic setVariable ["allowAirdrop", !_sling];
_logic setVariable ["allowSling", _sling];
// DROPS ARE RESPAWNS (user, 2026-11-02: "a respawn count for each support"):
// n drops is n - 1 respawns, now replacements for aircraft lost (virtual until
// tasked, the same day); its 0 (unlimited) is -1. Its Response Delay is
// retired with the new module's: the aircraft is made over the module when
// tasked.
private _drops = round (_logic getVariable ["drops", LEGACY_DROPS]);
_logic setVariable ["respawns", [_drops - 1, RESPAWNS_UNLIMITED] select (_drops <= 0)];
_logic setVariable ["capacity", LEGACY_CAPACITY];
_logic setVariable ["fulfillment", FULFIL_ONE];
_logic setVariable ["itemCooldown", LEGACY_ITEM_COOLDOWN];

INFO_1("%1 is an old Logistics Drop - read as JMSB - Logistics",_logic);

_this call FUNC(moduleLogistics);
