#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A
 * This function sets a player's radio channels based on their squad name.
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["bob"] call ymf_fnc_setRadioChannel
 *
 * Public: No
 */

params [["_player", objNull, [objNull]]];

// ACRE or TFAR. Game voice (jmfsb_voice) tunes nothing: a squad's nets come
// off the PAC net plan (jmfsb_pac_fnc_netPlan) and his Arma group.
if (!EGVAR(Patches,usesACRE) && !EGVAR(Patches,usesTFAR)) exitWith {};
if (!EGVAR(Settings,enableRadios)) exitWith {};
if (!EGVAR(init,isPlayer)) exitWith {};


// ACRE
if (EGVAR(patches,usesACRE)) exitWith {
    _player setVariable [QEGVAR(Player,RadioChannel), []];
    private _playerRadios = [_player] call acre_api_fnc_getCurrentRadioList;
    {
        if (_x != "") then {
            private _radio = [_x] call acre_api_fnc_getBaseRadio;
            private _channel = [[_player] call EFUNC(players,unit_getSquadName), _radio] call FUNC(getRadioChannel);

            [_x, _channel] call acre_api_fnc_setRadioChannel;
            INFO_3("Radio","%1 radio (%2) has its channel set to %3",_player,_x,_channel);

            // Store radio channels in variable.
            private _radioAndChannel = _player getVariable [QEGVAR(Player,RadioChannel), []];
            _radioAndChannel pushBack [_radio, _channel];
            _player setVariable [QEGVAR(Player,RadioChannel), _radioAndChannel];

        } else {
            SHOW_SERVER_WARNING_1("Radio","Empty radio is trying to get it's channel applied for %1",_player);
        };
    } forEach _playerRadios;
};

// TFAR - his sets loaded from the PAC NET PLAN and put on his squad's nets
// (jmfsb_adapter_tfar_fnc_tune: each net's frequency comes off the plan, the
// same plan game voice reads). His TEAM net and long range net are the
// squad's (jmfsb_pac_fnc_netPlanSquad).
if (isNil QEFUNC(adapter_tfar,tune) || {isNil QEFUNC(pac,netPlanSquad)}) exitWith {
    SHOW_SERVER_WARNING_1("Radio","TFAR tuning for %1 needs jmfsb_adapter_tfar and jmfsb_pac",_player);
};
private _squad = toUpper ([_player] call EFUNC(players,unit_getSquadName));
private _srNet = [_squad, PLAN_KIND_SR] call EFUNC(pac,netPlanSquad);
private _lrNet = [_squad, PLAN_KIND_LR] call EFUNC(pac,netPlanSquad);

// HIS PLATOON'S LONG RANGE, when the squad has no row of its own in the
// slotted plan (2026-09-09). Same table as ACRE - lrPlatoonChannel, keyed by
// platoon id - so the two radio systems are told the same thing once: the
// plan's long range net on that slot.
private _rows = missionNamespace getVariable ["jmfsbFR_radio_tfarNets", []];
if !(_rows isEqualType []) then {_rows = []};
private _hadRow = (_rows findIf {_x isEqualType [] && {toUpper (_x param [0, "", [""]]) isEqualTo _squad}}) >= 0;
private _plt = if (_hadRow) then {""} else {[_squad] call FUNC(platoonOf)};
if (_plt isNotEqualTo "") then {
    private _slot = PLAN_NO_SLOT;
    {
        if (!(_x isEqualType [])) then {continue};
        if (toUpper (_x param [0, ""]) isEqualTo toUpper _plt) exitWith {_slot = _x param [1, PLAN_NO_SLOT]};
    } forEach (missionNamespace getVariable ["jmfsbFR_radio_lrPlatoonChannel", []]);
    private _plan = ([] call EFUNC(pac,netPlan)) select {(_x select 2) isEqualTo PLAN_KIND_LR && (_x select 3) isEqualTo _slot};
    if (_plan isNotEqualTo []) then {_lrNet = (_plan select 0) select 0};
};

[_srNet, _lrNet] call EFUNC(adapter_tfar,tune);
INFO_3("Radio","%1 tuned from the net plan: %2 / %3",_player,_srNet,_lrNet);

