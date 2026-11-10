#include "script_component.hpp"
/*
 * Author: YonV
 * The CUSTOM patient the trainer set up, as the wound rows FUNC(patientSpawn)
 * takes: [body part, ACE damage type, damage] for each part with a wound.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[body part, ACE damage type, damage], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_training_fnc_customRows
 *
 * Public: No
 */

private _rows = [];
{
    _x params ["_kind", "_severity"];
    if (_kind > 0) then {
        _rows pushBack [BODY_PARTS # _forEachIndex, (WOUND_KINDS # _kind) # 0, (WOUND_SEVERITY # _severity) # 0];
    };
} forEach GVAR(custom);
_rows
