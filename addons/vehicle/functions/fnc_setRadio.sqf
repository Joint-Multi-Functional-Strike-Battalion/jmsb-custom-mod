#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A
 * This function changes the inventory of the given vehicle.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Channel <NUMBER>
 *
 * Return Value:
 * nothing
 *
 * Example:
 * [_vehicle] call ymf_fnc_vehicle_setRadio;
 *
 * Public: No
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_radioChannel", [], [[]]]
];

if (!EGVAR(Patches,usesACRE)) exitWith {};
if (!EGVAR(Settings,enableRadios)) exitWith {};
if (!EGVAR(Settings,enableVehicleRadios)) exitWith {};
if (isNull _vehicle) exitWith {};
if (!(_vehicle call EFUNC(systems,isValidFaction))) exitWith {};

// ACRE
if (EGVAR(patches,usesACRE)) exitWith {
    if (!isServer) exitWith {};

    [_vehicle, "default"] call acre_api_fnc_setVehicleRacksPreset;
    [_vehicle, {}] call acre_api_fnc_initVehicleRacks;

    waitUntil { _vehicle call acre_api_fnc_areVehicleRacksInitialized };

    INFO_2("VehicleRadio","Vehicle rack initzialized for %1 (%2)",_vehicle,typeOf _vehicle);

    // TWO 117Fs, MADE RATHER THAN HOPED FOR (user, 2026-09-02). ACRE's preset
    // gives a hull whatever its own author thought it should carry, which for
    // most of our fleet is nothing at all - and the plan leans on the racked
    // 117F for the sat link and for the mesh to relay through. So the racks are
    // counted and the missing ones added. See LR_RACKS in script_component.hpp.
    //
    // This runs BEFORE the empty-rack exit below on purpose: a vehicle with no
    // racks of its own is exactly the vehicle that needs these.
    private _have = 0;
    {
        private _mounted = [_x] call acre_api_fnc_getMountedRackRadio;
        if (count _mounted != 0 && {([_mounted] call acre_api_fnc_getBaseRadio) isEqualTo LR_RADIO}) then {
            _have = _have + 1;
        };
    } forEach ([_vehicle] call acre_api_fnc_getVehicleRacks);

    // THE FIRST IS THE SATCOM SET, the second the local one - see the defines.
    // A vehicle that already came with a 117F of its own keeps it and takes the
    // satcom slot, so only what is missing gets built.
    private _plan = [
        [LR_RACK_SAT_NAME, LR_RACK_SAT_SHORT, [[1, LR_SAT_ANTENNA]]],
        [LR_RACK_LOC_NAME, LR_RACK_LOC_SHORT, []]
    ];

    for "_i" from (_have + 1) to LR_RACKS do {
        (_plan select (_i - 1)) params ["_rackName", "_rackShort", "_components"];

        // removable, so a lead who dismounts can take the detachment net with
        // him instead of leaving it in a parked truck
        private _added = [
            _vehicle,
            [LR_RACK, _rackName, _rackShort, true, ["inside"], [], LR_RADIO, _components, []],
            true
        ] call acre_api_fnc_addRackToVehicle;

        if (_added) then {
            INFO_3("VehicleRadio","Added %1 rack (%2) to %3",_rackName,LR_RADIO,_vehicle);
        } else {
            SHOW_WARNING_2("VehicleRadio","Could not add the %1 rack to %2",_rackName,_vehicle);
        };
    };

    private _racks = [_vehicle] call acre_api_fnc_getVehicleRacks;
    if (count _racks == 0) exitWith {INFO_2("VehicleRadio","No Vehicle Racks discoverd for %1 (%2).",_vehicle,typeOf _vehicle);};

    private _lrSeen = 0;    // which 117F of the two this is - see the tuning below

    // Add extra channels
    _radioChannel = +_radioChannel;        // our own copy - append must not touch the caller's
    _radioChannel append [1,1,1,1,1];

    {
        private _radio = [_x] call acre_api_fnc_getMountedRackRadio;
        if (count _radio != 0) then {
            // THE 117Fs GO TO THEIR OWN HALF OF THE LR PLAN, not to the
            // caller's list - that list is the MR plan's channel numbers, and
            // reading them onto a long-range set would put the detachment net
            // on whatever the vehicle's medium-range slot happened to be.
            //
            // First 117F found is the satcom set, second is the low-power one,
            // in the order the racks were built above. The channels come from
            // the mission (config\config_radio.hpp) because the plan is the
            // mission's to write; the fallbacks are ACRE-safe numbers.
            private _channel = if (([_radio] call acre_api_fnc_getBaseRadio) isEqualTo LR_RADIO) then {
                _lrSeen = _lrSeen + 1;
                if (_lrSeen <= 1) then {
                    missionNamespace getVariable ["jmfsbFR_radio_lrSatChannel", missionNamespace getVariable ["jmfsbFR_radio_lrDefault", 1]]
                } else {
                    missionNamespace getVariable ["jmfsbFR_radio_lrLocalChannel", missionNamespace getVariable ["jmfsbFR_radio_lrDefault", 1]]
                };
            } else {
                _radioChannel select _forEachIndex
            };
            [_radio, _channel] call acre_api_fnc_setRadioChannel;
            INFO_5("VehicleRadio","Vehicle %1 (%2) radio %3 in rack %4 set to channel %5",_vehicle,typeOf _vehicle,_radio,_x,_channel);
        };
    } forEach _racks;
};

