#include "script_component.hpp"
/*
    File: fn_motorpool_init.sqf
    Author: YonV/JMSB
    Description: Hangs the MOTORPOOL screen on a controller object. One ACE
        action opens the UI; spawning, customization and removal all live
        inside it. The motorpool is the only vehicle-issuing screen; the old
        pad spawner it replaced is gone.

    Arguments:
    0: Controller <OBJECT> - the object carrying the ACE action + ledger
    1: Pad <OBJECT> - named helper (invisible helipad) vehicles appear on
    2-8: Category switches <BOOL> (optional, default true) - what this pad
        may offer, in config order: Cars, Armor, Mech, Heli, Plane, Boat,
        Static. A switch left out offers that category, so the old
        two-argument line keeps offering everything.
    9: Spawn heading <NUMBER> (optional) - degrees vehicles face when they
        appear, 0 north / 90 east. Left out, they face the way the PAD
        faces in Eden - this exists because an invisible helipad's
        rotation is invisible too, and an aircraft nosing into the hangar
        wall is how that gets noticed.
    10: Extra vehicles <ARRAY> (optional) - classnames THIS pad offers on
        top of the configs, each sorted onto its kind's tab (heli to HELI,
        ship to BOAT...). Named-for-this-pad beats the switches: the class
        is offered even when its whole category is switched off, so one
        pad can carry a single helicopter and no HELI list.
    11: Motorpool <STRING> (optional, default "") - which of the unit's
        TAC//PAC motorpools this pad shows (<unit>.motorpool.<name>, e.g.
        "air" at the airfield, "sea" at the dock) instead of the mission's
        current one (2026-11-07). Empty: the mission's.

    Example (controller init line in Eden - a land pad, no air, no boats,
    vehicles facing east, plus one pad-only transport helicopter):
    [this, motorpool_pad_1, true, true, true, false, false, false, true, 90, ["B_Heli_Transport_01_F"]] call jmfsb_vehicle_fnc_motorpool_init;
*/

params [
    "_controller", ["_pad", objNull, [objNull]],
    ["_cars", true, [true]], ["_armor", true, [true]], ["_mech", true, [true]],
    ["_heli", true, [true]], ["_plane", true, [true]], ["_boat", true, [true]],
    ["_static", true, [true]],
    ["_dir", -1, [0]],
    ["_extra", [], [[]]],
    ["_pool", "", [""]]
];

if (isNull _pad) then {_pad = _controller};

// Read back by fn_motorpool_open (category tabs + the pad's own list) and
// fn_motorpool_action (spawn heading; -1 = the pad's own).
_controller setVariable ["YMF_motorpool_allow", [_cars, _armor, _mech, _heli, _plane, _boat, _static]];
_controller setVariable ["YMF_motorpool_dir", _dir];
_controller setVariable ["YMF_motorpool_extra", _extra];
_controller setVariable ["YMF_motorpool_pool", _pool];

private _action = [
    "YMF_motorpool_open",
    "Motorpool",
    "a3\ui_f\data\gui\rsc\rscdisplayarsenal\spacegarage_ca.paa",
    {
        (_this select 2) params ["_controller", "_pad"];
        [_controller, _pad] call jmfsb_vehicle_fnc_motorpool_open;
    },
    {true},
    {},
    [_controller, _pad]
] call ace_interact_menu_fnc_createAction;

[_controller, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
