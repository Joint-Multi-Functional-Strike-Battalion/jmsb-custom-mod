#include "script_component.hpp"
/*
    File: fnc_uiTiles.sqf
    Author: YonV
    Description: A row of tiles - the website's `.tiles`: a panel each, an
        accent hairline along the top, a big number and a small label under
        it. Up to six across the content width.

    Parameters:
        0: Tiles <ARRAY> - [[value, label], ...]
        1: y <NUMBER> (optional)

    Returns:
        y under the tiles <NUMBER>
*/

params [["_tiles", [], [[]]], ["_y", PAC_UI_TOP, [0]]];

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {_y};

private _bgs = [PAC_IDC_TILE_BG1, PAC_IDC_TILE_BG2, PAC_IDC_TILE_BG3, PAC_IDC_TILE_BG4, PAC_IDC_TILE_BG5, PAC_IDC_TILE_BG6];
private _lines = [PAC_IDC_TILE_LINE1, PAC_IDC_TILE_LINE2, PAC_IDC_TILE_LINE3, PAC_IDC_TILE_LINE4, PAC_IDC_TILE_LINE5, PAC_IDC_TILE_LINE6];
private _txts = [PAC_IDC_TILE_TXT1, PAC_IDC_TILE_TXT2, PAC_IDC_TILE_TXT3, PAC_IDC_TILE_TXT4, PAC_IDC_TILE_TXT5, PAC_IDC_TILE_TXT6];

private _n = (count _tiles) min 6;
private _gap = 0.008;
private _w = (PAC_UI_W - (_n - 1) * _gap) / (_n max 1);
private _h = 0.084;

for "_i" from 0 to 5 do {
    if (_i >= _n) then {
        {([_x] call FUNC(uiCtrl)) ctrlShow false} forEach [_bgs # _i, _lines # _i, _txts # _i];
        continue;
    };
    (_tiles # _i) params ["_value", "_label"];
    private _x0 = PAC_UI_X + _i * (_w + _gap);
    [_bgs # _i, _x0, _y, _w, _h] call FUNC(uiPlace);
    [_lines # _i, _x0, _y, _w, 0.002] call FUNC(uiPlace);
    private _t = [_txts # _i, _x0 + 0.010, _y + 0.008, _w - 0.020, _h - 0.012] call FUNC(uiPlace);
    private _shown = if (_value isEqualType "") then {_value} else {
        if (_value isEqualType 0) then {_value toFixed 0} else {str _value}
    };
    _t ctrlSetStructuredText parseText format [
        "<t size='1.6' font='RobotoCondensedBold'>%1</t><br/><t size='0.7' color='#8b97a3'>%2</t>",
        [_shown] call FUNC(uiEsc), [toUpper _label] call FUNC(uiEsc)
    ];
};

_y + _h + 0.012
