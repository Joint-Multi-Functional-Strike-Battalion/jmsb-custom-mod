#include "script_component.hpp"
/*
 * Author: YonV
 * Maybe watches a safe house: the first player through the door draws 3-4
 * mortar rounds.
 *
 * JMSB's trap is mortars and only mortars. IED caches belong to ALiVE's own
 * IED system and jmfsb does not remake ALiVE systems - so a house is either
 * watched by somebody with a radio, or it is not.
 *
 * One roll per arming, and the watcher retires when it fires or when the
 * house is gone.
 *
 * Arguments:
 * 0: The house <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params ["_house"];

if (isNull _house) exitWith {};
if (_house getVariable [QGVAR(watched), false]) exitWith {};
if (random 100 >= GVAR(trapChance)) exitWith {};

_house setVariable [QGVAR(watched), true];

[{
    params ["_args", "_handle"];
    _args params ["_house"];

    if (isNull _house) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    private _in = allPlayers findIf {
        alive _x && {_x distance _house < LEADERS_HOUSE_R}
    };
    if (_in < 0) exitWith {};

    [_handle] call CBA_fnc_removePerFrameHandler;
    _house setVariable [QGVAR(watched), false];

    private _rounds = 3 + floor random 2;
    // [pos, rounds, spread, shell, window] - the third caller caught still
    // using fireBarrage's old ammo-first shape after its refactor. The
    // string in the rounds slot meant every trap fired the default three
    // 155s, not its own mortars.
    [getPosATL _house, _rounds, LEADERS_TRAP_DISP, LEADERS_TRAP_AMMO, _rounds * 5]
        call EFUNC(common,fireBarrage);

    INFO_2("safe house at %1 was watched - %2 round(s)",
        mapGridPosition (getPosATL _house),_rounds);
}, 5, [_house]] call CBA_fnc_addPerFrameHandler;
