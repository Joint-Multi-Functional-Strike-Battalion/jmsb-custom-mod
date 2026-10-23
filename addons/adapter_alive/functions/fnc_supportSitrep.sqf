#include "script_component.hpp"
/*
 * Author: JMSB
 * Asks one air combat-support asset for a SITREP, the way ALiVE's tablet
 * does (misc/fn_getSitrep in the WORKSHOP pbo, the build the game loads):
 * everything is read straight off the live vehicle - grid, the destination
 * of NEO_radioCurrentTask for an ETA, damage folded with ammo into a
 * Green/Amber/Red condition, fuel likewise - and the two radio lines go out
 * on the side channel. The readable summary also comes back for the app's
 * own verdict row, so the answer lands where the button was pressed.
 *
 * AIR ONLY. An artillery entry's element 0 is the battery leader, a man -
 * his "fuel" and "airframe damage" are nonsense - and the battery's rounds
 * ledger is already on the screen.
 *
 * Arguments:
 * 0: Asset id from FUNC(supportAssets), "alive:type:index" or "alive:ato"
 *    <STRING> - the "alive" provider's sitrep code, called through
 *    EFUNC(support,sitrep)
 *
 * Return Value:
 * 0: Answered <BOOL>
 * 1: The report, or why not <STRING>
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

if (_assetId isEqualTo SUPPORT_ATO_ID) exitWith {
    [true, "The ATO answers requests as its airframes come free."]
};

if (isNil "NEO_radioLogic") exitWith {[false, "ALiVE combat support is not running"]};

(_assetId splitString ":") params ["", ["_type", ""], ["_idxText", "-1"]];
if (!(_type in ["cas", "transport"])) exitWith {[false, "SITREP is for airframes"]};

private _arrName = ["NEO_radioTrasportArray_%1", "NEO_radioCasArray_%1"] select (_type isEqualTo "cas");
private _entry = (NEO_radioLogic getVariable [format [_arrName, side group player], []]) param [parseNumber _idxText, []];
_entry params [["_veh", objNull], "", ["_callsign", ""]];

if (isNull _veh || {!alive _veh}) exitWith {[false, "that unit is gone"]};

private _me = format ["%1", group player];
if (!isNil "NEO_fnc_callsignFix") then {_me = _me call NEO_fnc_callsignFix};

private _pos = getPosATL _veh;

// The destination the airframe is actually working - element 1 of the task
// the FSM banked on consume. No task, no leg to time.
private _task = _veh getVariable ["NEO_radioCurrentTask", []];
private _eta = "HOLDING";
if (_task isNotEqualTo []) then {
    private _dist = (_task param [1, _pos]) distance2D _pos;
    _eta = switch (true) do {
        case (speed _veh > 1 && {(_pos select 2) > 5}): {
            format ["ETA %1 MIN", (round (_dist / ((speed _veh) / 3.6) / 60)) max 1]
        };
        case (speed _veh > 1): {"TAKING OFF"};
        default {"ON THE GROUND"};
    };
};

// ALiVE's AMCAS: ammo fraction folded with hull damage, thirds to colours.
private _ammo = 1;
if (!isNil "ALiVE_fnc_vehicleGetAmmo") then {
    private _rows = _veh call ALiVE_fnc_vehicleGetAmmo;
    if (_rows isNotEqualTo []) then {
        private _avail = 0;
        {_avail = _avail + ((_x select 1) / ((_x select 2) max 1))} forEach _rows;
        _ammo = _avail / count _rows;
    };
};
private _cond = ((1 - _ammo) + damage _veh) / 2;
private _fnc_band = {
    params ["_v"];
    switch (true) do {
        case (_v >= 0.6): {"RED"};
        case (_v > 0.3): {"AMBER"};
        default {"GREEN"};
    }
};
private _condText = [_cond] call _fnc_band;
private _fuelText = [1 - fuel _veh] call _fnc_band;

// The exchange ALiVE's own button broadcasts - request now, answer on a
// short delay, both on the side channel. Guarded: no net, no theatre.
if (!isNil "NEO_fnc_messageBroadcast") then {
    [[player, format ["%1 this is %2, send SITREP. Over.", _callsign, _me], "side"], "NEO_fnc_messageBroadcast", true, false] spawn BIS_fnc_MP;
    [{
        [[player, _this, "side"], "NEO_fnc_messageBroadcast", true, false] spawn BIS_fnc_MP;
    }, format ["%1 this is %2. Grid %3, %4, condition %5, fuel %6. Over.", _me, _callsign, mapGridPosition _pos, toLower _eta, _condText, _fuelText], 6] call CBA_fnc_waitAndExecute;
};

INFO_2("supportSitrep: %1 answered - %2",_callsign,_eta);

[true, format ["%1: GRID %2 - %3 - COND %4 - FUEL %5", _callsign, mapGridPosition _pos, _eta, _condText, _fuelText]]
