#include "script_component.hpp"

if (hasInterface && !isServer) exitWith {};

params [
    ["_logic",objNull,[objNull]],
    ["_units",[],[[]]],
    ["_activated", true]
];



if (_activated) then {
    private _area = _logic getVariable ["objectArea",[0,0,0,false,0]];

    if ((_area param [0, 0]) == 0) exitWith {WARNING_1("Bad size? %1",_area);};

    /* format ["%1\n%2\n%3\n%4\n%5", _logic,_units,_activated,_area,(getPos _logic)] remoteExec ["hint", 0]; */
    [{
        (_this select 0) params ["_area"];
        {
            // AT THE PLAYER, not here - fullHealLocal and the ACM resets are
            // locality-bound (the adminpanel's own fullHeal remoteExecs the
            // same call), so running them on the server healed nobody but
            // the host. ACM guarded: without that mod the calls are absent.
            private _p = _x;
            // ONLY A MAN WHO NEEDS IT (review P8, 2026-10-31): every man in the
            // area got eight remote calls and a banner every second, hurt or not.
            // The readings are ACE's public ones.
            private _hurt = damage _p > 0
                || {(_p getVariable ["ace_medical_woundBleeding", 0]) > 0}
                || {(_p getVariable ["ace_medical_bloodVolume", HEAL_FULL_BLOOD]) < HEAL_FULL_BLOOD}
                || {_p getVariable ["ace_medical_inPain", false]}
                || {_p getVariable ["ACE_isUnconscious", false]};
            if (!_hurt) then {continue};
            {
                if (!isNil _x) then {
                    [_p] remoteExec [_x, _p];
                };
            } forEach [
                "ACM_core_fnc_resetVariables",
                "ACM_airway_fnc_resetVariables",
                "ACM_breathing_fnc_resetVariables",
                "ACM_circulation_fnc_resetVariables",
                "ACM_damage_fnc_resetVariables",
                "ACM_disability_fnc_resetVariables"
            ];
            [_p] remoteExec ["ace_medical_treatment_fnc_fullHealLocal", _p];
            _p setDamage 0;
            [
                "<t color='#FFA500'>You are being treated at the 3Jmfsb Medical Zone</t>",
                -1,
                0.8,
                0.5,
                0,
                0,
                789
            ] remoteExec ["BIS_fnc_dynamicText", _x];
        }forEach (allPlayers inAreaArray _area);
    },1, [[(getPos _logic)] + _area]] call CBA_fnc_addPerFrameHandler;
};
