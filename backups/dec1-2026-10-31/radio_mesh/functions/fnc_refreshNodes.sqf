#include "script_component.hpp"
/*
 * Author: JMSB
 * Rebuilds this client's relay table: every radio of a relay-capable base
 * type that a player carries or a vehicle has racked, with the frequency its
 * current channel receives on, its transmit power and its side. Runs on the
 * refresh cadence; fnc_signal only reads the result.
 *
 * Relay rules (user, 2026-08-28): manpacks and racks only, same side only.
 * AI carry no ACRE radios, so the players and the vehicles are the whole net.
 *
 * Arguments: None (per-frame handler)
 *
 * Return Value: None
 *
 * Public: No
 */
if (!GVAR(hasACRE)) exitWith {};
if (!GVAR(enabled)) exitWith { GVAR(nodes) = [] };

private _types = (GVAR(nodeRadios) splitString ", ") apply {toUpper _x};
private _nodes = [];

private _fnc_add = {
    params ["_radio", "_owner"];
    if (_radio isEqualTo "") exitWith {};
    private _base = [_radio] call acre_api_fnc_getBaseRadio;
    if (!(toUpper _base in _types)) exitWith {};
    private _preset = [_radio] call acre_api_fnc_getPreset;
    private _channel = [_radio] call acre_api_fnc_getRadioChannel;
    private _freq = [_base, _preset, _channel, "frequencyRX"] call acre_api_fnc_getPresetChannelField;
    if (!(_freq isEqualType 0)) exitWith {};
    private _power = [_base, _preset, _channel, "power"] call acre_api_fnc_getPresetChannelField;
    if (!(_power isEqualType 0)) then { _power = 0 };
    private _side = if (_owner isKindOf "CAManBase") then {side group _owner} else {
        private _cmd = effectiveCommander _owner;
        if (isNull _cmd) then {side _owner} else {side group _cmd}
    };
    _nodes pushBack [_radio, _freq, _power, _side, _owner];
};

// Carried: every player's radios
{
    private _unit = _x;
    if (alive _unit) then {
        { [_x, _unit] call _fnc_add } forEach ([_unit] call acre_api_fnc_getCurrentRadioList);
    };
} forEach allPlayers;

// Racked: every vehicle whose racks ACRE has set up
if (!isNil "acre_api_fnc_areVehicleRacksInitialized") then {
    {
        private _veh = _x;
        if (alive _veh && {[_veh] call acre_api_fnc_areVehicleRacksInitialized}) then {
            {
                [[_x] call acre_api_fnc_getMountedRackRadio, _veh] call _fnc_add;
            } forEach ([_veh] call acre_api_fnc_getVehicleRacks);
        };
    } forEach vehicles;
};

GVAR(nodes) = _nodes;

// The leg cache is keyed by radio ids and dated; anything older than the TTL
// is dropped here rather than on every signal call.
private _now = diag_tickTime;
{
    if (_now - (_y select 0) > MESH_EDGE_TTL) then { GVAR(edgeCache) deleteAt _x };
} forEach +GVAR(edgeCache);
