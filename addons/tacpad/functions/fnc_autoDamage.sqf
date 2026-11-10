#include "script_component.hpp"
/*
 * Author: YonV
 * Autofill source "vehicleDamage" (report-card review, user 2026-11-02, D17):
 * the state of the vehicle the sender is in, as the DEFREP's DAMAGE line
 * words it - the engine knows it exactly. The player may tick another.
 *
 *   GREEN   under AUTO_DAMAGE_SLIGHT and it moves
 *   YELLOW  under AUTO_DAMAGE_HEAVY and it moves
 *   RED     worse, or it cannot move (a static weapon is not asked to)
 *   BLACK   destroyed
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The state word, "" on foot <STRING>
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_autoDamage
 *
 * Public: No
 */

private _veh = vehicle player;
if (_veh isEqualTo player) exitWith {""};

private _damage = damage _veh;
private _stuck = !(_veh isKindOf "StaticWeapon") && !canMove _veh;

switch (true) do {
    case (!alive _veh): {AUTO_BLACK};
    case (_stuck || _damage >= AUTO_DAMAGE_HEAVY): {AUTO_RED};
    case (_damage >= AUTO_DAMAGE_SLIGHT): {AUTO_YELLOW};
    default {AUTO_GREEN};
}
