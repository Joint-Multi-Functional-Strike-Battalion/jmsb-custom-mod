#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_radioApply

Description:
    Writes a radio plan - the structure's "radio" section, the shape
    config_radio.hpp used to set by hand - into the jmfsbFR_radio_*
    globals this machine's readers use, and re-programs the ACRE presets
    when the plan actually changed under them.

    THREE MOMENTS. This addon's preInit, with an empty plan and
    onlyMissing = true: every global the mod reads exists from then on
    (FUNC(radioKeys)'s defaults), so a mission that ships no plan does not
    throw on the first bare read. The mission's own preInit then overwrites
    those with its plan when it has one. The server's boot, once the
    structure is final: the database's plan (or the mission's, seeded)
    goes on. And every client when it takes the server's structure
    (FUNC(takeServer)).

    NETS. The plan's nets (FUNC(netPlan)) are made in RF on the server
    whenever the plan changed (FUNC(netPlanSync)); nothing is tuned - voice
    is game VoIP and the plan names nets, not frequencies.

    RE-PROGRAMMING (ACRE only). gear's setupRadios wrote the ACRE presets from the
    globals at postInit, on every machine; a plan that arrives after that
    would leave the presets stale, so when a channel list changed and a
    plan is present the presets are written again. A radio already in
    somebody's hands keeps what it was issued with until it is re-tuned -
    which taking a slot does.

Parameters:
    0: The plan {key -> value} <HASHMAP> (optional, default empty)
    1: Only write globals that are nil <BOOL> (optional, default false)

Returns:
    Whether any global changed <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_radio", createHashMap, [createHashMap]], ["_onlyMissing", false, [false]]];

private _changed = false;
{
    _x params ["_key", "_default"];
    private _name = "jmfsbFR_radio_" + _key;
    if (_onlyMissing && {!isNil _name}) then {continue};
    private _v = _radio getOrDefault [_key, _default];
    if (isNil _name || {(missionNamespace getVariable _name) isNotEqualTo _v}) then {
        missionNamespace setVariable [_name, _v];
        _changed = true;
    };
} forEach ([] call FUNC(radioKeys));

private _hasPlan = (_radio getOrDefault ["srChannels", []]) isNotEqualTo []
    || {(_radio getOrDefault ["mrChannels", []]) isNotEqualTo []}
    || {(_radio getOrDefault ["tfarNets", []]) isNotEqualTo []};

if (_changed && _hasPlan && {!isNil "jmfsb_gear_fnc_setupRadios"} && {!isNil "jmfsb_Settings_enableRadios"}) then {
    call jmfsb_gear_fnc_setupRadios;
    INFO("radio plan from the structure applied - presets re-programmed");
};

if (_changed && isServer) then {[] call FUNC(netPlanSync)};

_changed
