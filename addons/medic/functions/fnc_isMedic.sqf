#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether a man is a CLS or a medic - who the MEDIC tile and app are for.
 *
 * THE PAC SKILLS DECIDE. TAC//PAC publishes the abbreviations of the skills a
 * man holds onto his unit (jmfsb_pac_skillTags, see EFUNC(pac,applySkills)),
 * and CLS or MED there is the answer. The same skills set ACE's medic class
 * and the engine's Medic trait - CLS 1, Medic 2, addons/acm/README.md - and
 * PAC clears both before it applies a man's skills, so either of them is the
 * same answer read another way. They are also what a mission without PAC has.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Is a CLS or medic <BOOL>
 *
 * Example:
 * [player] call jmfsb_medic_fnc_isMedic
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {false};

private _tags = _unit getVariable [QEGVAR(pac,skillTags), []];
if !(_tags isEqualType []) then {_tags = []};

(_tags findIf {_x in MEDIC_TAGS}) > -1
    || {(_unit getVariable [ACEV_MEDIC_CLASS, 0]) in [1, 2]}
    || {_unit getUnitTrait "Medic"}
