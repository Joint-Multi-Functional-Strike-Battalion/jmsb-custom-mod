#include "script_component.hpp"
/*
 * Author: JMSB
 * The status row's cells, left to right: each icon of GVAR(overlayOrder)
 * asked of its provider (GVAR(overlayProviders), FUNC(overlayProviders)). An
 * icon with no provider, or a provider that answers nothing usable, is a dim
 * "--" rather than a gap, so the row keeps its shape.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Cells, [[icon word, value, state], ...] <ARRAY>
 *
 * Example:
 * private _cells = [] call jmfsb_devices_fnc_overlayStatus
 *
 * Public: No
 */

private _providers = missionNamespace getVariable [QGVAR(overlayProviders), createHashMap];
((missionNamespace getVariable [QGVAR(overlayOrder), []]) select [0, OVERLAY_STATUS_CELLS]) apply {
    private _icon = _x;
    private _cell = [] call (_providers getOrDefault [_icon, {}]);
    if (isNil "_cell" || {!(_cell isEqualType [])} || {count _cell < 3}) then {[_icon, "--", STATE_OFF]} else {_cell}
}
