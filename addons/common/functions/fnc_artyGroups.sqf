#include "script_component.hpp"
/*
 * Author: JMSB
 * The artillery teams of a side: the groups with a player in them whose ORBAT
 * squad kind - the map icon set on the squad's row in the ORBAT, carried on
 * the group as jmfsb_bft_type (jmfsb_groups_fnc_groupKind) - is an artillery
 * kind, "art" or "mortar" (user, 2026-10-25: "need a way in the orbat to set
 * the arty team"). Read by the counter-battery radar's messages and the ARTY
 * tile.
 *
 * Arguments:
 * 0: Side <SIDE>
 *
 * Return Value:
 * Groups <ARRAY>
 *
 * Example:
 * [west] call jmfsb_common_fnc_artyGroups
 *
 * Public: Yes
 */

params [["_side", sideUnknown, [sideUnknown]]];

allGroups select {
    side _x isEqualTo _side
    && {(toLower (_x getVariable [ARTY_KIND_VAR, ""])) in ARTY_KINDS}
    && {((units _x) findIf {isPlayer _x}) >= 0}
}
