#include "script_component.hpp"
/*
 * Author: JMSB
 * Repaints every open panel from the current theme. Changing the scheme while
 * the map is open takes effect on the next tick rather than the next time the
 * map is opened, which is the difference between a colour setting you can judge
 * and one you have to guess at.
 *
 * The frame is repainted here; a panel's own contents are repainted by its
 * refresher, because only the panel knows which of its rows are accent and
 * which are ink.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

if (!hasInterface) exitWith {};

uiNamespace setVariable [QGVAR(themeCache), nil];
([] call FUNC(theme)) params ["_ground", "_ink", "_accent", "_line"];

{
    _y params ["_group"];
    if (isNull _group) then {continue};

    private _panel = GVAR(panels) get _x;
    if (isNil "_panel") then {continue};

    private _slot = _panel get "slot";

    private _fill = _group controlsGroupCtrl IDC_GROUND(_slot);
    if (!isNull _fill) then {
        _fill ctrlSetBackgroundColor _ground;
    };

    {
        if (!isNull _x) then {
            _x ctrlSetBackgroundColor _ink;
        };
    } forEach ((_group getVariable [QGVAR(frame), []]) + [_group controlsGroupCtrl IDC_RULE(_slot)]);

    private _header = _group controlsGroupCtrl IDC_HEADER(_slot);
    if (!isNull _header) then {
        _header ctrlSetBackgroundColor [0, 0, 0, 0];
    };

    private _title = _group controlsGroupCtrl IDC_TITLE(_slot);
    if (!isNull _title) then {
        _title ctrlSetStructuredText parseText format [
            "<t font='RobotoCondensedBold' size='0.85' color='%1'>%2</t>",
            _ink call BIS_fnc_colorRGBAtoHTML,
            [toUpper (_panel get "title")] call FUNC(xmlSafe)
        ];
    };
} forEach GVAR(open);
