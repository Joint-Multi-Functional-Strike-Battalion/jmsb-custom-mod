#include "script_component.hpp"

// ON THE SUPPORT PAGE, AS A PROVIDER OF THE SUPPORT CORE. The core merges every
// registered provider's rows and routes an order back by the id's prefix -
// "cas" is ours, and the ids FUNC(entityRow) hands out carry it, so neither
// the page nor any other provider ever holds this addon's name.
//
// Registered on EVERY machine, not only the server: the page is drawn on the
// client and reads its rows locally.
[SUPPORT_KIND, createHashMapFromArray [
    ["assets", FUNC(assets)],
    ["task", FUNC(task)],
    ["sitrep", FUNC(sitrep)],
    ["available", FUNC(assetAvailable)],
    ["preview", FUNC(preview)],
    ["overlay", FUNC(overlay)],
    ["types", SUPPORT_TYPES]
]] call EFUNC(support,registerProvider);

// THE SERVER FLIES THE RUNS. A request raised on a client lands here.
if (isServer) then {
    [QGVAR(request), {_this call FUNC(request)}] call CBA_fnc_addEventHandler;

    // Recall is a flag rather than a direct delete: the run watch owns the
    // aircraft's life, and two things deleting one airframe is how a
    // <NULL-object> ends up in a ledger.
    [QGVAR(abort), {
        params [["_logic", objNull, [objNull]]];
        if (isNull _logic) exitWith {};
        // Nothing in the air, nothing to recall. A flag raised on an idle
        // asset (cooling down or expended reads idle here) would sit there
        // and kill the next run on its first tick.
        if ((_logic getVariable [QGVAR(status), "idle"]) isEqualTo "idle") exitWith {};
        _logic setVariable [QGVAR(abort), true, true];
    }] call CBA_fnc_addEventHandler;
};

if (!hasInterface) exitWith {};

// WHAT THE MAN ON THE RADIO HEARS. The run is flown on the server and every
// word of it is said here, so a strike is not a thing that silently happens
// somewhere - it is called inbound, and its terminal guidance is read back so
// the JTAC knows whether his smoke was seen.
[QGVAR(inbound), {
    params [["_logic", objNull, [objNull]], ["_pos", [], [[]]], ["_delay", 0, [0]], ["_mode", "strike", [""]]];
    if (isNull _logic) exitWith {};
    if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group player)) exitWith {};

    ["SUPPORT", format [
        "%1 %2 %3, %4 sec",
        _logic getVariable [QGVAR(callsign), "CAS"],
        ["inbound to", "moving to hold over"] select (_mode isEqualTo "loiter"),
        mapGridPosition _pos,
        round _delay
    ], "high"] call EFUNC(messaging,notify);
}] call CBA_fnc_addEventHandler;

// THE HANDOVER. A loitering drone is an ISR asset, not a strike, and the thing
// that makes it one is a man in the gunner's seat: the aircraft holds its own
// orbit and the drone controller gets the optics, the sensors and whatever the
// airframe is hung with. Nothing on the server decides what that ordnance is
// for any more - he does.
//
// THE MAN WHO ASKED FOR IT GETS IT, AND ONLY IF HE IS ISR. A drone link is
// exclusive - it drops whatever else that player was flying - so linking every
// drone controller on the side to a new airframe would take the last one out
// from under someone mid-task. Everyone else on the side is told it is up
// there; the aircraft is on their DRONES board and they can take it themselves
// when the man who called it is done.
//
// NO UAV TERMINAL (user, 2026-10-20: out of the arsenal). The link and the seat
// are the devices' own (jmfsb_devices_fnc_uavControl): the UAV operator trait,
// the players' side, the DATA link, and remoteControl rather than a terminal.
[QGVAR(onStation), {
    params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_caller", objNull, [objNull]]];
    if (isNull _logic || {isNull _veh}) exitWith {};
    if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group player)) exitWith {};

    private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];

    if (player isNotEqualTo _caller) exitWith {
        ["SUPPORT", format ["%1 on station over %2 - holding", _callsign, mapGridPosition _veh], "normal"] call EFUNC(messaging,notify);
    };

    // A DRONE IS FLOWN BY A DRONE CONTROLLER. The ISR flag is the mission's own
    // - one variable, set on the man whose job this is, and the same one the
    // hacking tablet gates on - so a rifleman who calls a loiter gets an
    // aircraft holding overhead and his ISR gets the seat.
    if !([player] call EFUNC(common,isISR)) exitWith {
        ["SUPPORT", format ["%1 on station - your ISR operator can take the feed from his DRONES board", _callsign], "high"] call EFUNC(messaging,notify);
    };

    // The link first: without it there is no seat, and the man is told why
    // (uavControl says it - not the UAV operator, no DATA link, ...).
    if (isNil QEFUNC(devices,uavControl)) exitWith {
        WARNING_1("%1: jmfsb_devices is not loaded - no drone control without a UAV terminal",_callsign);
    };
    if !(["link", _veh] call EFUNC(devices,uavControl)) exitWith {
        ["SUPPORT", format ["%1 on station - holding; you cannot take it", _callsign], "high"] call EFUNC(messaging,notify);
    };

    ["SUPPORT", format ["%1 on station - you have the gunner", _callsign], "high"] call EFUNC(messaging,notify);

    // THE SEAT ONE SECOND LATER, as it always was: the airframe and its crew
    // are a moment old, and a seat asked for in the frame they appear in asks
    // an AI that is not settled yet.
    [{
        params ["_veh", "_callsign"];
        if (!alive _veh) exitWith {};

        private _gunner = gunner _veh;
        if (isNull _gunner) then {_gunner = _veh turretUnit [0]};
        if (isNull _gunner) exitWith {
            WARNING_2("'%1' has no gunner's seat - %2 keeps the link and nothing else",typeOf _veh,_callsign);
        };

        ["take", _veh, _gunner] call EFUNC(devices,uavControl);
    }, [_veh, _callsign], 1] call CBA_fnc_waitAndExecute;
}] call CBA_fnc_addEventHandler;

// THE SEAT IS GIVEN BACK BEFORE THE AIRFRAME GOES. Recalled, shot down or out
// of patience, FUNC(egress) says so here first - when the run ends, and again
// before the airframe is deleted off the map edge - because a controller left
// in the turret of a vehicle that is deleted under him is a black screen he
// cannot get out of. Dropping the link gives the seat back first.
[QGVAR(offStation), {
    params [["_veh", objNull, [objNull]]];
    if (isNull _veh || {isNil QEFUNC(devices,uavControl)}) exitWith {};
    if ((["linked"] call EFUNC(devices,uavControl)) isNotEqualTo _veh) exitWith {};

    ["unlink"] call EFUNC(devices,uavControl);
}] call CBA_fnc_addEventHandler;

[QGVAR(release), {
    params [["_logic", objNull, [objNull]], ["_aim", [], [[]]], ["_by", "grid", [""]]];
    if (isNull _logic) exitWith {};
    if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group player)) exitWith {};

    // The word for what guided it, in the JTAC's own vocabulary - "spot" is a
    // laser, and a man who lit one wants to know it was the thing used.
    private _word = switch (_by) do {
        case "laser": {"on your spot"};
        case "smoke": {"on your smoke"};
        default {"on the grid"};
    };

    ["SUPPORT", format [
        "%1 in hot %2 - %3",
        _logic getVariable [QGVAR(callsign), "CAS"],
        _word,
        mapGridPosition _aim
    ], "high"] call EFUNC(messaging,notify);
}] call CBA_fnc_addEventHandler;
