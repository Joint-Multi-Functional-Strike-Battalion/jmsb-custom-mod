#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the system's adapter in use (jmfsb_voice_adapter / _adapterId) from
 * the ones registered (FUNC(registerAdapter)): under LiveKit the one of that
 * id; under game VON the last registered that is not LiveKit's, else "von";
 * under "none" no adapter. Every hook the adapter does not give keeps its
 * neutral default. Nothing is done when the adapter in use is already the one
 * wanted. Called on every registration and every system choice
 * (FUNC(selectSystem)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The adapter id in use, "" for none yet <STRING>
 *
 * Example:
 * [] call jmfsb_voice_fnc_applyAdapter
 *
 * Public: No
 */

private _id = "";
switch (true) do {
    // "none": the server's system cannot run here, no adapter
    case (!GVAR(active)): {};
    // the voice server's own adapter, registered under the system's id
    case (GVAR(system) isNotEqualTo SYSTEM_VON): {
        if (GVAR(system) in GVAR(adapters)) then {_id = GVAR(system)};
    };
    // game VON: a mission's or mod's adapter over the default, never the
    // other way; the voice server's never
    default {
        private _own = GVAR(adapterIds) select {_x isNotEqualTo SYSTEM_LIVEKIT};
        private _chosen = _own select {_x isNotEqualTo DEFAULT_ADAPTER};
        _id = switch (true) do {
            case (_chosen isNotEqualTo []): {_chosen select -1};
            case (DEFAULT_ADAPTER in _own): {DEFAULT_ADAPTER};
            default {""};
        };
    };
};
if (_id isEqualTo GVAR(adapterId)) exitWith {_id};

private _adapter = +GVAR(adapterDefaults);
if (_id isNotEqualTo "") then {
    {
        if (_y isEqualType {}) then {_adapter set [_x, _y]};
    } forEach (GVAR(adapters) get _id);
};
GVAR(adapter) = _adapter;
GVAR(adapterId) = _id;
INFO_2("voice adapter in use: %1 (system %2)",_id,GVAR(system));
_id
