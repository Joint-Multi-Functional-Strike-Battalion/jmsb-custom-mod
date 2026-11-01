#include "script_component.hpp"

params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

private _boat = vehicle _unit; // yes, this will even work if _unit is the unmanned boat itself

// NOTE: getHit / getHitIndex will oftentimes falsely return 0 ,
//       hence we need to remember the previos damage.
private _damageVar = format ["grad_safeboating_damage_%1", _selection];

// PUBLIC ONLY ON A CHANGE (review P8, 2026-10-31): HandleDamage fires many times
// a hit, and each public set went to every machine. The value is public at all
// only so the next machine to own the boat starts from it.
if (!(isNull _source && (_projectile == "") && isNull _instigator)) exitWith {
    if ((_boat getVariable [_damageVar, -1]) isNotEqualTo _damage) then {
        _boat setVariable [_damageVar, _damage, true];
    };
    nil
};

private _absSpeed = abs speed _boat;
private _maxAllowedDamage = _absSpeed / 50;


private _previousDamage = _boat getVariable [_damageVar, 0];
LOG_4("%1 previous damage %2, new damage value %3; speed damage could be %4",_boat,_previousDamage,_damage,_maxAllowedDamage);
private _finalDamage = (_maxAllowedDamage min _damage) max _previousDamage;
LOG_3("set damage %1 to boat part '%2' from bumping into things at speed %3",_finalDamage,_selection,_absSpeed);
if (_finalDamage isNotEqualTo _previousDamage) then {
    _boat setVariable [_damageVar, _finalDamage, true];
};
_finalDamage
