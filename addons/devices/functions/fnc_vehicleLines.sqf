#include "script_component.hpp"
/*
 * Author: JMSB
 * What VEHICLE STATUS says, as three columns of lines for FUNC(vehicleColumn)
 * to draw: DAMAGE and FUEL; AMMUNITION and COUNTERMEASURES; APS, the VOICE NETS
 * and the CREW. Kept apart from the drawing so the page is measured before it
 * is built - FUNC(appVehicle) sizes the frame off these lines.
 *
 * Colours are THEME TOKEN NAMES, resolved by the drawer through
 * jmfsb_tacpad_fnc_theme, or TONE_ALERT. Green and amber are the fixed swatches
 * (TONE_OK, TONE_WARN), drawn as fills; red is TONE_ALERT, drawn as an
 * inverted accent block with a word in the value, because the accent is only
 * red on some schemes and a hue alone would not tell amber from red.
 *
 * WORST FIRST, AND THE CREW LAST. Damage groups are sorted worst first (ties
 * keep DAMAGE_GROUPS order), so a red part is at the top and never the one cut
 * to "+N MORE". The right column puts APS and the voice nets above the crew, and
 * folds the passengers into one PAX row with only the hurt ones listed - a
 * troop carrier's cargo would otherwise push the set off the page.
 *
 * A line is one of:
 *   ["head", title, right label]
 *   ["gap"]
 *   ["bar", label, fill 0..1, tone, value]
 *   ["row", left, right, left token, right tone, bold, indent level]
 *
 * Every read is someone else's: the engine's hit points, fuel and magazines,
 * FUNC(vehicleSeats) (ON BOARD's own), jmfsb_aps' charges and holds on the
 * vehicle, and the voice API (FUNC(vehicleRf)). A system that is not
 * loaded says so in its own section.
 *
 * Arguments:
 * 0: The vehicle <OBJECT>
 *
 * Return Value:
 * Three columns, each an array of lines <ARRAY>
 *
 * Example:
 * [vehicle player] call jmfsb_devices_fnc_vehicleLines
 *
 * Public: No
 */

params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle) exitWith {[[], [], []]};

private _fnc_damageTone = {
    params ["_damage"];
    [TONE_OK, TONE_WARN, TONE_ALERT] select ((parseNumber (_damage >= DAMAGE_WARN)) + (parseNumber (_damage >= DAMAGE_ALERT)))
};
private _fnc_pct = {
    params ["_fraction"];
    format ["%1%2", round (_fraction * PERCENT), "%"]
};
private _fnc_rounds = {
    params ["_rounds", "_mags"];
    format ["%1  %2 MAG%3",
        [format ["%1 RDS", _rounds], WORD_EMPTY] select (_rounds <= 0),
        _mags, ["S", ""] select (_mags == 1)
    ]
};

// ---------------------------------------------------------- DAMAGE, FUEL ----
private _left = [];
private _damage = [_vehicle] call FUNC(vehicleDamage);
private _hitParts = 0;
{_hitParts = _hitParts + (_x select 2)} forEach _damage;

// Worst first; a tie keeps the groups' own order, so all-green rows never move.
private _sorted = [];
{
    _sorted pushBack [-(_x select 1), _forEachIndex, _x];
} forEach _damage;
_sorted sort true;
_damage = _sorted apply {_x select 2};

_left pushBack ["head", "DAMAGE", ["ALL GREEN", format ["%1 PARTS HIT", _hitParts]] select (_hitParts > 0)];
if (_damage isEqualTo []) then {
    _left pushBack ["row", "NO PART DATA", "", "dim", "dim", false, 0];
};
{
    _x params ["_label", "_worst", "_hit", "_parts"];
    private _value = [1 - _worst] call _fnc_pct;
    if (_hit > 0 && _parts > 1) then {
        _value = format ["%1  %2/%3", _value, _hit, _parts];
    };
    if (_worst >= DAMAGE_ALERT) then {
        _value = format ["%1 %2", WORD_DAMAGE_ALERT, _value];
    };
    _left pushBack ["bar", _label, 1 - _worst, [_worst] call _fnc_damageTone, _value];
} forEach _damage;

([_vehicle] call FUNC(vehicleFuel)) params ["_fuel", "_range"];
private _fuelTone = switch (true) do {
    case (_fuel < FUEL_ALERT): {TONE_ALERT};
    case (_fuel < FUEL_WARN): {TONE_WARN};
    default {TONE_OK};
};
private _fuelValue = [_fuel] call _fnc_pct;
if (_fuel < FUEL_ALERT) then {
    _fuelValue = format ["%1 %2", WORD_FUEL_ALERT, _fuelValue];
};
_left pushBack ["gap"];
_left pushBack ["head", "FUEL", ""];
_left pushBack ["bar", "TANK", _fuel, _fuelTone, _fuelValue];
_left pushBack ["row", "RANGE",
    ["MEASURING", format ["~%1 KM", round (_range / METRES_PER_KM)]] select (_range >= 0),
    "muted", ["dim", "ink"] select (_range >= 0), false, 0
];

// ------------------------------------------ AMMUNITION, COUNTERMEASURES ----
private _middle = [];
([_vehicle] call FUNC(vehicleAmmo)) params ["_turrets", "_countermeasures"];

_middle pushBack ["head", "AMMUNITION", format ["%1 TURRET%2", count _turrets, ["S", ""] select (count _turrets == 1)]];
if (_turrets isEqualTo []) then {
    _middle pushBack ["row", "NO WEAPONS", "", "dim", "dim", false, 0];
};
{
    _x params ["_turret", "_weapons"];
    _middle pushBack ["row", _turret, "", "muted", "muted", true, 0];
    {
        _x params ["_weapon", "_mags"];
        _middle pushBack ["row", _weapon, "", "ink", "ink", true, 1];
        {
            _x params ["_magName", "_count", "_rounds"];
            _middle pushBack [
                "row", _magName, [_rounds, _count] call _fnc_rounds,
                "ink", ["ink", TONE_ALERT] select (_rounds <= 0), false, 2
            ];
        } forEach _mags;
    } forEach _weapons;
} forEach _turrets;

_countermeasures params ["_smokeRounds", "_smokeMags", "_flareRounds", "_flareMags"];
_middle pushBack ["gap"];
_middle pushBack ["head", "COUNTERMEASURES", ""];
{
    _x params ["_label", "_rounds", "_mags"];
    if (_mags isEqualTo 0) then {
        _middle pushBack ["row", _label, "NONE", "muted", "dim", false, 0];
    } else {
        _middle pushBack ["row", _label, [_rounds, _mags] call _fnc_rounds, "muted", ["ink", TONE_ALERT] select (_rounds <= 0), false, 0];
    };
} forEach [["SMOKE", _smokeRounds, _smokeMags], ["FLARES", _flareRounds, _flareMags]];

// -------------------------------------------------- APS, VOICE NETS, CREW ----
private _right = [];

// APS: jmfsb_aps' public charge count and the fit, charges by side and holds
// it keeps on the vehicle (the APS panel's own reads). Read only - the
// switches stay on the APS panel.
if (isNil QEFUNC(aps,charges)) then {
    _right pushBack ["head", "APS", ""];
    _right pushBack ["row", "APS NOT LOADED", "", "dim", "dim", false, 0];
} else {
    private _fit = _vehicle getVariable [QEGVAR(aps,fit), APS_FIT_NONE];
    private _rf = _vehicle getVariable [QEGVAR(aps,rf), false];
    private _max = _vehicle getVariable [QEGVAR(aps,ammoMax), 0];
    _right pushBack ["head", "APS", toUpper (_vehicle getVariable [QEGVAR(aps,name), ""])];
    if (_fit isEqualTo APS_FIT_NONE && {!_rf}) exitWith {
        _right pushBack ["row", "NOT FITTED", "", "dim", "dim", false, 0];
    };
    if (_fit isNotEqualTo APS_FIT_NONE) then {
        private _charges = [_vehicle] call EFUNC(aps,charges);
        private _hkHold = _vehicle getVariable [QEGVAR(aps,hkHold), false];
        private _chargesSaid = format ["L %1/%2  R %3/%4", _vehicle getVariable [QEGVAR(aps,ammoL), 0], _max, _vehicle getVariable [QEGVAR(aps,ammoR), 0], _max];
        if (_charges <= 0) then {
            _chargesSaid = format ["%1  %2", WORD_EMPTY, _chargesSaid];
        };
        _right pushBack ["row", format ["HARD KILL %1", _fit], _chargesSaid,
            "muted", ["ink", TONE_ALERT] select (_charges <= 0), false, 0
        ];
        _right pushBack ["row", "LAUNCHERS", ["ON", "HOLD"] select _hkHold, "muted", ["ink", TONE_WARN] select _hkHold, false, 0];
    };
    if (_rf) then {
        private _live = alive _vehicle && {isEngineOn _vehicle};
        private _cooldown = (_vehicle getVariable [QEGVAR(aps,rfReady), 0]) - CBA_missionTime;
        private _rfHold = _vehicle getVariable [QEGVAR(aps,rfHold), false];
        _right pushBack ["row", "RF BURST", switch (true) do {
            case (!_live): {"COLD"};
            case (_cooldown > 0): {format ["%1 S", ceil _cooldown]};
            case (_rfHold): {"HOLD"};
            default {"READY"};
        }, "muted", ["ink", TONE_WARN] select (_rfHold || _cooldown > 0), false, 0];
    };
};

// VOICE: the nets the player is on aboard, VEH (the intercom) among them.
([_vehicle] call FUNC(vehicleRf)) params ["_rfState", "_nets"];
_right pushBack ["gap"];
_right pushBack ["head", "VOICE NETS", ["", format ["%1 NETS", count _nets]] select (_rfState isEqualTo "on")];
switch (_rfState) do {
    case "off": {_right pushBack ["row", "NO VOICE ADDON", "", "dim", "dim", false, 0]};
    case "none": {_right pushBack ["row", "NOT ABOARD", "", "dim", "dim", false, 0]};
    default {
        if (_nets isEqualTo []) then {
            _right pushBack ["row", "ON NO NET", "", "dim", "dim", false, 0];
        };
        {
            _x params ["_net", "_reach", "_active", "_kind"];
            private _said = switch (true) do {
                case (!_reach): {"NO ROUTE"};
                case (_active): {"ACTIVE"};
                case (_kind isEqualTo VOICE_KIND_VEH): {"INTERCOM"};
                default {"MON"};
            };
            _right pushBack ["row", _net, _said, "ink", [TONE_ALERT, TONE_OK] select _reach, false, 0];
        } forEach _nets;
    };
};

// CREW: the crew seats one row each; the passengers as one PAX row, with only
// the hurt ones under it, worst first.
private _seats = [_vehicle] call FUNC(vehicleSeats);
private _me = call CBA_fnc_currentUnit;
private _crewTones = createHashMapFromArray [[CREW_OK, TONE_OK], [CREW_WIA, TONE_WARN], [CREW_UNCON, TONE_WARN], [CREW_KIA, TONE_ALERT]];
private _severity = CREW_SEVERITY;

_right pushBack ["gap"];
_right pushBack ["head", "CREW", format ["%1 / %2", count _seats, count (fullCrew [_vehicle, "", true])]];
{
    _x params ["", "_name", "_seat", "_man", "_state"];
    _right pushBack ["row", format ["%1  %2", _seat, _name], _state, "ink", _crewTones getOrDefault [_state, "ink"], _man isEqualTo _me, 0];
} forEach (_seats select {(_x select 2) isNotEqualTo SEAT_PAX});

private _pax = _seats select {(_x select 2) isEqualTo SEAT_PAX};
if (_pax isNotEqualTo []) then {
    private _hurt = [];
    {
        private _state = _x select 4;
        if (_state isNotEqualTo CREW_OK) then {
            _hurt pushBack [_severity find _state, _x select 1, _forEachIndex];
        };
    } forEach _pax;
    _hurt sort true;

    private _worstState = if (_hurt isEqualTo []) then {CREW_OK} else {(_pax select ((_hurt select 0) select 2)) select 4};
    _right pushBack ["row", format ["%1  %2", SEAT_PAX, count _pax],
        [format ["%1 HURT", count _hurt], CREW_OK] select (_hurt isEqualTo []),
        "ink", _crewTones getOrDefault [_worstState, "ink"], false, 0
    ];
    {
        (_pax select (_x select 2)) params ["", "_name", "", "_man", "_state"];
        _right pushBack ["row", _name, _state, "ink", _crewTones getOrDefault [_state, "ink"], _man isEqualTo _me, 1];
    } forEach _hurt;
};

[_left, _middle, _right]
