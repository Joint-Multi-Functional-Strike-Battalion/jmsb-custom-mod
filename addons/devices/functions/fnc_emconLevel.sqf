#include "script_component.hpp"
/*
 * Author: YonV
 * The player's EMCON as EW last told this client: the highest level on any
 * of his sets. Read off jmfsb_ew's client slice (jmfsb_ew_mine, index 2: his
 * sets, each [id, profile, emcon, exposure m, nets] - jmfsb_ew_fnc_publish),
 * which the server refreshes as soon as the EW app's EP tab sets a level.
 *
 * THE HIGHEST, NOT PER SET: voice closes every radio net of his when any one
 * set is at EMCON 3 (jmfsb_voice_fnc_blockLevel), so that is what a net cell
 * must say.
 *
 * A SOFT READ: jmfsb_ew is not required. Without it, or before its first
 * slice lands, the answer is 0 (no EMCON).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * EMCON level, 0 none <NUMBER>
 *
 * Example:
 * private _silent = ([] call jmfsb_devices_fnc_emconLevel) >= 3
 *
 * Public: No
 */

private _mine = missionNamespace getVariable [QEGVAR(ew,mine), []];
if !(_mine isEqualType []) exitWith {0};

private _level = 0;
{
    if (_x isEqualType []) then {
        _level = _level max (_x param [EW_NODE_EMCON, 0, [0]]);
    };
} forEach (_mine param [EW_SLICE_NODES, [], [[]]]);

_level
