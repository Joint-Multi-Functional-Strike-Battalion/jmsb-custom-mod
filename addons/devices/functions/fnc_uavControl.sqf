#include "script_component.hpp"
/*
 * Author: JMSB
 * DRONE CONTROL WITHOUT A UAV TERMINAL. The vanilla terminal is out of the
 * arsenal (user, 2026-10-20), and connectTerminalToUAV / isUAVConnectable both
 * want one in the GPS slot - so the devices fly drones themselves: the UAV
 * operator (FUNC(uavCan)) links ONE drone of his own side, and takes a seat in
 * it with the engine's remoteControl and switchCamera, the way Zeus's remote
 * control does (BIS_fnc_moduleRemoteControl). No terminal item, no side-locked
 * terminal class.
 *
 *   "link"        links the drone - the DRONES board's CONNECT. One at a time,
 *                 like a terminal: linking another drops the first. Public on
 *                 the drone (jmfsb_devices_uavOperator) so nobody else takes it.
 *                 A drone linked on the ground with no home yet gets that spot
 *                 as its home (jmfsb_devices_uavHome, FUNC(uavHome)).
 *   "unlink"      gives the seat back first, then drops the link (DISCONNECT)
 *   "take"        a seat in the linked drone - the one given, else the gunner's
 *                 (the driver's when there is none). Closes the tablet or the
 *                 map first so the player is looking through it, and takes the
 *                 seat the next frame.
 *   "release"     gives the seat back: objNull remoteControl, the camera back
 *                 on the player in the view he left in, the action removed
 *   "linked"      the linked drone, objNull for none <OBJECT>
 *   "flying"      the drone he is in a seat of, objNull for none <OBJECT>
 *
 * The way out from inside: the drone's action menu (UAV_RELEASE_TITLE) or the
 * tablet key. FUNC(uavTick) lets go by itself on death, unconsciousness, a lost
 * DATA link, a lost seat, the trait or the side going, or the camera coming
 * back to the player on its own.
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Drone <OBJECT> (optional, default objNull)
 * 2: Seat to take - a crew unit of the drone <OBJECT> (optional, default objNull = gunner, else driver)
 *
 * Return Value:
 * Done <BOOL>, or the drone for "linked" / "flying" <OBJECT>
 *
 * Example:
 * ["link", _uav] call jmfsb_devices_fnc_uavControl
 * ["take", _uav] call jmfsb_devices_fnc_uavControl
 * ["release"] call jmfsb_devices_fnc_uavControl
 *
 * Public: Yes
 */

params [["_mode", "", [""]], ["_uav", objNull, [objNull]], ["_seat", objNull, [objNull]]];

private _fnc_say = {
    params ["_text"];
    if (isNil QEFUNC(messaging,notify)) exitWith {};
    [UAV_NOTIFY_TITLE, _text, "high"] call EFUNC(messaging,notify);
};

switch (_mode) do {
    case "linked": {GVAR(uavLinked)};
    case "flying": {[objNull, GVAR(uavFlying)] select GVAR(uavActive)};

    case "link": {
        ([_uav] call FUNC(uavCan)) params ["_ok", "_why"];
        if (!_ok) exitWith {
            [_why] call _fnc_say;
            false
        };
        if (GVAR(uavLinked) isEqualTo _uav) exitWith {true};

        ["unlink"] call FUNC(uavControl);
        GVAR(uavLinked) = _uav;
        _uav setVariable [QGVAR(uavOperator), player, true];
        // A drone linked sitting on the ground is on its pad: that is its home
        // for RTB (FUNC(uavHome)) unless whatever launched it said otherwise.
        if ((_uav getVariable [QGVAR(uavHome), []]) isEqualTo [] && {isTouchingGround _uav}) then {
            _uav setVariable [QGVAR(uavHome), getPosATL _uav, true];
        };
        true
    };

    case "unlink": {
        if (GVAR(uavActive)) then {["release"] call FUNC(uavControl)};
        private _old = GVAR(uavLinked);
        GVAR(uavLinked) = objNull;
        if (isNull _old) exitWith {false};

        // Only his own claim is cleared - a dead body's too, after a respawn.
        private _claim = _old getVariable [QGVAR(uavOperator), objNull];
        if (_claim isEqualTo player || !alive _claim) then {
            _old setVariable [QGVAR(uavOperator), nil, true];
        };
        true
    };

    case "take": {
        if (GVAR(uavLinked) isNotEqualTo _uav || isNull _uav) exitWith {
            ["Connect to the drone first."] call _fnc_say;
            false
        };
        ([_uav] call FUNC(uavCan)) params ["_ok", "_why"];
        if (!_ok) exitWith {
            [_why] call _fnc_say;
            false
        };

        if (isNull _seat) then {_seat = gunner _uav};
        if (isNull _seat) then {_seat = _uav turretUnit [0]};
        if (isNull _seat) then {_seat = driver _uav};
        if (!alive _seat || (vehicle _seat) isNotEqualTo _uav) exitWith {
            ["That drone has no seat to take."] call _fnc_say;
            false
        };

        if (GVAR(uavActive)) then {["release"] call FUNC(uavControl)};

        // Out of the screen first: a seat taken under the map is a seat the
        // player cannot see through.
        [] call FUNC(close);
        if (visibleMap) then {openMap [false, false]};

        [{
            params ["_uav", "_seat"];
            if (!alive _seat || !alive player || GVAR(uavLinked) isNotEqualTo _uav) exitWith {};

            GVAR(uavView) = cameraView;
            player remoteControl _seat;
            _uav switchCamera ([UAV_VIEW_GUNNER, UAV_VIEW_DRIVER] select (_seat isEqualTo driver _uav));

            GVAR(uavActive) = true;
            GVAR(uavSeat) = _seat;
            GVAR(uavFlying) = _uav;
            _uav setVariable [QGVAR(uavFlown), true, true];
            GVAR(uavAction) = _uav addAction [
                UAV_RELEASE_TITLE, {["release"] call FUNC(uavControl)}, nil, UAV_RELEASE_PRIORITY,
                false, true, "", QUOTE(GVAR(uavActive))
            ];
        }, [_uav, _seat]] call CBA_fnc_execNextFrame;
        true
    };

    case "release": {
        if (!GVAR(uavActive)) exitWith {false};
        private _seat = GVAR(uavSeat);
        private _flown = GVAR(uavFlying);
        GVAR(uavActive) = false;
        GVAR(uavSeat) = objNull;
        GVAR(uavFlying) = objNull;

        if (!isNull _seat) then {objNull remoteControl _seat};
        if (!isNull _flown) then {
            _flown removeAction GVAR(uavAction);
            _flown setVariable [QGVAR(uavFlown), nil, true];
        };
        GVAR(uavAction) = -1;

        // The camera back on the man, in the view he left in - Zeus's own exit.
        player switchCamera GVAR(uavView);
        true
    };

    default {
        WARNING_1("uavControl: unknown mode '%1'",_mode);
        false
    };
};
