#include "script_component.hpp"
/*
 * Author: YonV
 * A man's job, as the three or four letters a net calls him by.
 *
 * OFF ENGINE TRAITS, NOT OFF A MOD. Medic, engineer, EOD and UAV are traits the
 * game itself carries and every mission sets one way or another, so this works
 * on a mission that has never heard of jmfsb. Leadership is asked last because a
 * section commander who is also the medic is the medic to anybody calling for
 * one.
 *
 * IT IS STAMPED AT SEND TIME, not read back later - see FUNC(srvSubmit). A man
 * who was the medic when he sent a CASEVAC is still the man who sent it after he
 * has been promoted, and a tag that changes retrospectively is a tag that lies
 * about the traffic.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Short role tag, "" when nothing distinguishes him <STRING>
 *
 * Example:
 * private _tag = [player] call jmfsb_messaging_fnc_roleTag
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {""};

if (_unit getUnitTrait "medic") exitWith {"MED"};
if (_unit getUnitTrait "engineer") exitWith {"ENG"};
if (_unit getUnitTrait "explosiveSpecialist") exitWith {"EOD"};
if (_unit getUnitTrait "UAVHacker") exitWith {"UAV"};

// Leader last, and only of a group with somebody in it - "leader" of a
// one-man group is a man on his own.
if (_unit isEqualTo (leader group _unit) && {count (units group _unit) > 1}) exitWith {"LDR"};

""
