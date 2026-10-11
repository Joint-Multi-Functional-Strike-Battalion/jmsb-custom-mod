#include "script_component.hpp"
/*
    File: fn_motorpool_select.sqf
    Author: YonV/JMSB
    Description: A list row was picked - fill the right pane: name, class
        tag, the spec sheet (crew/pax, armament, countermeasures, top speed,
        all read from the vehicle config), and the CUSTOMIZE lists built
        from fn_vehicle_cosmeticEntries for this class - labels starting
        "Toggle" are fittings, everything else is a paint scheme.

    Example:
    [] call jmfsb_vehicle_fnc_motorpool_select;
*/

private _d = uiNamespace getVariable ["YMF_motorpool_dlg", displayNull];
if (isNull _d) exitWith {};

(uiNamespace getVariable ["YMF_motorpool_theme", []]) params ["", "_ink", "_accent"];
private _inkHex = _ink call BIS_fnc_colorRGBAtoHTML;
private _muteHex = [_ink # 0, _ink # 1, _ink # 2, 0.62] call BIS_fnc_colorRGBAtoHTML;

private _lnb = _d displayCtrl 130;
private _paintsLb = _d displayCtrl 164;
private _fitsLb = _d displayCtrl 166;
private _row = lnbCurSelRow _lnb;

lbClear _paintsLb;
lbClear _fitsLb;
uiNamespace setVariable ["YMF_motorpool_paints", []];
uiNamespace setVariable ["YMF_motorpool_fits", []];

if (_row < 0) exitWith {
    (_d displayCtrl 106) ctrlSetText "";
    (_d displayCtrl 107) ctrlSetText "";
    (_d displayCtrl 150) ctrlSetStructuredText parseText "";
};

private _data = _lnb lnbData [_row, 0];

// ------------------------------------------------------- the SPAWNED tab --
if ((_data select [0, 2]) isEqualTo "s:") exitWith {
    (uiNamespace getVariable ["YMF_motorpool_ctx", [objNull]]) params ["_controller"];
    private _entry = (_controller getVariable ["YMF_spawnedVehicles", []]) param [parseNumber (_data select [2]), []];
    _entry params [["_veh", objNull], ["_owner", ""]];
    if (isNull _veh) exitWith {};

    private _cfg = configOf _veh;
    (_d displayCtrl 106) ctrlSetText toUpper getText (_cfg >> "displayName");
    (_d displayCtrl 107) ctrlSetText format ["SPAWNED BY %1", toUpper _owner];
    (_d displayCtrl 150) ctrlSetStructuredText parseText format [
        "<t color='%1' size='0.8'>GRID </t><t color='%2'>%3</t><br/><t color='%1' size='0.8'>CREW ABOARD </t><t color='%2'>%4</t>",
        _muteHex, _inkHex, mapGridPosition _veh,
        count ((fullCrew _veh) select {alive (_x select 0)})
    ];
};

// ----------------------------------------------------------- a spawnable --
private _cfg = configFile >> "CfgVehicles" >> _data;

(_d displayCtrl 106) ctrlSetText toUpper getText (_cfg >> "displayName");

private _sub = getText (_cfg >> "editorSubcategory");
private _tag = toUpper getText (configFile >> "CfgEditorSubcategories" >> _sub >> "displayName");
(_d displayCtrl 107) ctrlSetText _tag;

// crew, pax
private _crew = [_data, true] call BIS_fnc_crewCount;
private _pax = getNumber (_cfg >> "transportSoldier");

// armament: every turret's weapons, recursively; horns and fake weapons are
// noise, smoke is a countermeasure not a gun
private _weapons = getArray (_cfg >> "weapons");
private _fnc_turrets = {
    params ["_turretsCfg"];
    {
        _weapons append (getArray (_x >> "weapons"));
        [_x >> "Turrets"] call _fnc_turrets;
    } forEach ("true" configClasses _turretsCfg);
};
[_cfg >> "Turrets"] call _fnc_turrets;

private _cm = [];
private _named = [];
{
    private _w = _x;
    switch (true) do {
        case ("Horn" in _w): {};
        case (_w isEqualTo "FakeWeapon"): {};
        case ("SmokeLauncher" in _w): {_cm pushBack "SMOKE"};
        case ("CMFlareLauncher" in _w): {_cm pushBack "FLARES"};
        default {
            private _wName = getText (configFile >> "CfgWeapons" >> _w >> "displayName");
            if (_wName isNotEqualTo "") then {_named pushBack toUpper _wName};
        };
    };
} forEach _weapons;
_named = _named arrayIntersect _named;
_cm = _cm arrayIntersect _cm;

private _line = {
    params ["_label", "_value"];
    format ["<t color='%1' size='0.8'>%2  </t><t color='%3'>%4</t><br/>", _muteHex, _label, _inkHex, _value]
};

(_d displayCtrl 150) ctrlSetStructuredText parseText (
    (["CREW / PAX", format ["%1 CREW%2", _crew, ["", format [" + %1 PAX", _pax]] select (_pax > 0)]] call _line)
    + (["ARMAMENT", [_named joinString " - ", "NONE"] select (_named isEqualTo [])] call _line)
    + (["COUNTERMEASURES", [_cm joinString " - ", "NONE"] select (_cm isEqualTo [])] call _line)
    + (["TOP SPEED", format ["%1 KM/H", getNumber (_cfg >> "maxSpeed")]] call _line)
);

// -------------------------------------------------------------- customize --
private _paints = [];
private _fits = [];
{
    _x params ["_base", "_label", "_iconCode"];
    if (_data isKindOf _base) then {
        if ((_label select [0, 6]) isEqualTo "Toggle") then {
            _fits pushBack [_label select [7], _iconCode param [1, {}], false];
        } else {
            _paints pushBack [_label, _iconCode param [1, {}]];
        };
    };
} forEach ((call jmfsb_vehicle_fnc_cosmeticEntries) + ([_data, call jmfsb_vehicle_fnc_cosmeticEntries] call jmfsb_vehicle_fnc_factoryPaints));   // the config's own paints fill the gaps

uiNamespace setVariable ["YMF_motorpool_paints", _paints];
uiNamespace setVariable ["YMF_motorpool_fits", _fits];

// The chosen row carries a marker - see fn_motorpool_paintPick. AS
// DELIVERED is the hull's own paint and starts marked, so the list always
// shows which one is going on the vehicle rather than relying on a
// selection highlight the dark scheme all but hides.
_paintsLb lbAdd " >  AS DELIVERED";
{_paintsLb lbAdd format ["    %1", toUpper (_x select 0)]} forEach _paints;
_paintsLb lbSetCurSel 0;

{_fitsLb lbAdd format ["[ OFF ]  %1", toUpper (_x select 0)]} forEach _fits;
if (_fits isEqualTo []) then {_fitsLb lbAdd "NOTHING FITTABLE ON THIS HULL"};
