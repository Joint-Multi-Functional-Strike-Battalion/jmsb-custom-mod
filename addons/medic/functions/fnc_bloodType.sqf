#include "script_component.hpp"
/*
 * Author: JMSB
 * A man's blood type, the way a medic gets it: off his dog tags. Always shown,
 * monitored or not - it is stamped on him, not measured.
 *
 * ACM FIRST. ACM keeps the type as a number (ACM_circulation_BloodType, -1
 * until it has been rolled) and publishes it. Failing that, ACE's dog tag data
 * (ace_dogtags_dogtagData, its third field); and failing that, ACE's own
 * getDogtagData is asked, which works the tag out and publishes it - the same
 * thing that happens when somebody checks his tags by hand. Under ACM that
 * call is ACM's override, which rolls the blood type as well.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Blood type, "UNKNOWN" when there is no tag to read <STRING>
 *
 * Example:
 * [_unit] call jmfsb_medic_fnc_bloodType
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {"UNKNOWN"};

private _acm = _unit getVariable [ACMV_BLOOD_TYPE, -1];
if !(_acm isEqualType 0) then {_acm = -1};
if (_acm >= 0 && _acm < count BLOOD_TYPES) exitWith {BLOOD_TYPES select _acm};

private _tags = _unit getVariable [ACEV_DOGTAG_DATA, []];
if (_tags isEqualTo [] && {!isNil "ace_dogtags_fnc_getDogtagData"}) then {
    _tags = [_unit] call ace_dogtags_fnc_getDogtagData;
};

if !(_tags isEqualType []) exitWith {"UNKNOWN"};

private _type = _tags param [2, ""];
if (!(_type isEqualType "") || _type isEqualTo "") exitWith {"UNKNOWN"};

_type
