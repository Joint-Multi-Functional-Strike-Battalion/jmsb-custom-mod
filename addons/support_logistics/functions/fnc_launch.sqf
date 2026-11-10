#include "script_component.hpp"
/*
 * Author: YonV
 * Puts a delivery in the air and starts its watch - server, at once when the
 * request is accepted (FUNC(deliver)).
 *
 * VIRTUAL UNTIL TASKED (user, 2026-11-02: "all support aircraft needs to be
 * virtual till tasked, then they spawn in at alt over the support module
 * location"): every aircraft of the delivery is made now, in the air over
 * the module at its flight height (FUNC(spawnAircraft)), flies the delivery,
 * then flies back to the module and is removed there - crew and airframe,
 * its escorts with it (FUNC(dropTick), FUNC(slingTick)).
 *
 *   AIRDROP  one aircraft carries the whole cart (FUNC(dropTick)); it is
 *            pointed past the point, so it never turns back over the drop
 *   SLING    one helicopter per item, each with its item on the hook, side
 *            by side SLING_SPACING apart, each putting its load on the
 *            ground as far apart round the point by support_air's flight
 *            control (FUNC(slingTick), 2026-11-05 - Simplex's set-down). An
 *            item the hook will not take is left out and said
 *
 * THE SORTIE is one hashmap every watch of this delivery holds: the point,
 * the requester, what was ordered, what has been delivered and what was not,
 * the aircraft still out. FUNC(account) closes the asset's thread from it
 * when the last item is accounted for; FUNC(aircraftDone) ends the delivery
 * when the last aircraft is gone.
 *
 * NEVER LAUNCHED - recalled first, or no aircraft could be made - the
 * delivery is given back and the thread is DECLINED (2026-11-01).
 *
 * TACTICAL HEIGHTS (user, 2026-11-01), the support core's: an airdrop
 * aircraft appears over the module at the height EFUNC(support,approachHeight)
 * gives for its distance from the point - its transit height far out (nap of
 * the earth for a helicopter, the fixed-wing transit altitude for a plane),
 * the drop height close - and comes to the drop height on the way in
 * (FUNC(dropTick)). A sling helicopter flies nap of the earth with the rope
 * and the load added under it; the module's Sling Flight Height is retired.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Task token <STRING>
 * 2: Delivery point ATL <ARRAY>
 * 3: The cart <ARRAY>
 * 4: Airdrop height above the terrain, m <NUMBER>
 * 5: Marking class, "" for none <STRING>
 * 6: Who asked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "AIRDROP", _pos, [[0, 1]], 250, "SmokeShellBlue", player] call jmfsb_support_logistics_fnc_launch
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_task", "", [""]],
    ["_pos", [], [[]]],
    ["_cart", [], [[]]],
    ["_height", DEF_DROP_HEIGHT, [0]],
    ["_signal", "", [""]],
    ["_requester", objNull, [objNull]]
];

if (isNull _logic) exitWith {};

private _fnc_never = {
    params ["_line"];
    _logic setVariable [QGVAR(abort), false, true];
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    _logic setVariable [QGVAR(plan), [], true];
    _logic setVariable [QGVAR(sortie), nil];
    [_logic, _line, "normal", _requester, false] call FUNC(say);
    [_logic, "DECLINED", _line] call FUNC(threadState);
    _logic setVariable [QGVAR(threadJob), nil];
};

if (_logic getVariable [QGVAR(abort), false]) exitWith {["stood down"] call _fnc_never};

private _catalog = _logic getVariable [QGVAR(catalog), []];
private _queue = [];
{
    _x params ["_i", "_c"];
    for "_k" from 1 to _c do {_queue pushBack _i};
} forEach _cart;

// Made over the module, and back to it to be removed.
(_logic getVariable [QGVAR(home), getPosATL _logic]) params ["_hx", "_hy"];
private _start = [_hx, _hy, 0];
private _exit = +_start;

private _sortie = createHashMapFromArray [
    ["pos", _pos],
    ["requester", _requester],
    ["total", count _queue],
    ["delivered", []],
    ["failed", []],
    ["why", ""],
    ["closed", false],
    ["aircraft", []],
    // What was put down, for a NOT FOUND (step 7, FUNC(threadReply)).
    ["items", []]
];
_logic setVariable [QGVAR(sortie), _sortie];
private _aircraft = _sortie get "aircraft";
private _notLaunched = [];

if (_task isEqualTo TASK_AIRDROP) then {
    private _cls = _logic getVariable [QGVAR(cls), ""];
    private _veh = [_logic, _start, _pos, [_cls, _height, _start distance2D _pos] call EFUNC(support,approachHeight)] call FUNC(spawnAircraft);
    if (!alive _veh) exitWith {};
    _aircraft pushBack _veh;
    [_veh, _pos getPos [OVERFLY, _start getDir _pos], "NORMAL"] call EFUNC(support_air,moveTo);
    private _st = createHashMapFromArray [
        ["phase", PHASE_IN],
        ["height", _height],
        ["queue", _queue],
        ["exit", _exit],
        ["signal", _signal],
        ["until", CBA_missionTime + SORTIE_TIMEOUT]
    ];
    [FUNC(dropTick), DROP_TICK, [_logic, _veh, _st, _sortie]] call CBA_fnc_addPerFrameHandler;
} else {
    private _right = (_start getDir _pos) + 90;
    // Made with the load's hang under nap of the earth, then flown at the
    // support core's sling height once the load is on the hook.
    private _cruise = ([_logic getVariable [QGVAR(cls), ""], FLY_TRANSIT] call EFUNC(support,flightHeight)) + SLING_HANG;
    {
        // 0, 1 right, 1 left, 2 right, 2 left ... spacings off the line in.
        private _off = ceil (_forEachIndex / 2) * SLING_SPACING;
        private _dir = _right + ([180, 0] select (_forEachIndex % 2 isEqualTo 1));
        private _from = _start getPos [_off, _dir];
        private _to = _pos getPos [_off, _dir];
        private _entry = _catalog select _x;
        private _name = _entry select ITEM_NAME;

        private _veh = [_logic, _from, _to, _cruise] call FUNC(spawnAircraft);
        if (!alive _veh) then {
            _notLaunched pushBack [_name, "no aircraft could be made"];
            continue;
        };
        private _item = [_logic, _entry, (getPosATL _veh) vectorAdd [0, 0, -SLING_HANG], getDir _veh] call FUNC(spawnItem);
        if (isNull _item || {!(_veh canSlingLoad _item)} || {!(_veh setSlingLoad _item)}) then {
            WARNING_2("'%1' would not take '%2' on the hook",typeOf _veh,_name);
            deleteVehicle _item;
            [_veh] call EFUNC(support_air,sweep);
            _notLaunched pushBack [_name, format ["%1 would not go on the hook", _name]];
            continue;
        };
        _aircraft pushBack _veh;
        [_veh, FLY_TRANSIT] call EFUNC(support,flyAt);
        [_veh, _to, "NORMAL"] call EFUNC(support_air,moveTo);
        private _st = createHashMapFromArray [
            ["phase", PHASE_IN],
            ["pos", _to],
            ["exit", _exit],
            ["item", _item],
            ["name", _name],
            ["signal", _signal],
            ["until", CBA_missionTime + SORTIE_TIMEOUT]
        ];
        [FUNC(slingTick), AIR_TICK, [_logic, _veh, _st, _sortie]] call CBA_fnc_addPerFrameHandler;
    } forEach _queue;
};

if (_aircraft isEqualTo []) exitWith {
    private _why = (_notLaunched param [0, ["", "no aircraft could be made"]]) select 1;
    [format ["could not launch - %1", _why]] call _fnc_never;
};

// DRONE ESCORTS (user, 2026-11-02: "drone escorts is based on lz security for
// helos and always for fix wings"): two with the first aircraft of the
// delivery - fixed-wing drones for a plane always, rotary drones for a
// helicopter only when the request's LZ security is YELLOW or RED
// (EFUNC(support_air,escortLaunch)). Made beside it, removed with it.
[_logic, _aircraft select 0, _pos, format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _logic getVariable [QGVAR(side), west]] call EFUNC(support_air,escortLaunch);

private _line = format ["airborne with %1, inbound %2", [[_catalog, _cart] call FUNC(cartNames)] call FUNC(countLine), mapGridPosition _pos];
_logic setVariable [QGVAR(vehicle), _aircraft select 0, true];
_logic setVariable [QGVAR(status), STATUS_INBOUND, true];
_logic setVariable [QGVAR(plan), [[_pos, _task], [_exit, PLAN_BASE]], true];
[_logic, _line, "normal", _requester] call FUNC(say);
// WHEELS UP "INBOUND - ETA m:ss" in the thread a message tasked it with (user,
// 2026-11-01: "need more information like after rw inbound eta"), then ON
// TASK in the asset's thread, if one was filed to it.
private _jobThread = (_logic getVariable [QGVAR(threadJob), createHashMap]) getOrDefault ["thread", ""];
if (_jobThread isNotEqualTo "") then {
    private _eta = [[_aircraft select 0, _pos] call EFUNC(support,etaTo)] call EFUNC(support,etaText);
    [
        format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
        _jobThread,
        CARD_WHEELS_UP,
        [[CARD_TEXT_KEY, [mapGridPosition (_aircraft select 0), format [WHEELS_UP_INBOUND, _eta]] select (_eta isNotEqualTo "")]],
        _logic getVariable [QGVAR(callsign), DEF_CALLSIGN]
    ] call EFUNC(support,fileCard);
};
[_logic, "IN_PROGRESS", _line] call FUNC(threadState);

// What never left is accounted for now, after ON TASK: the thread closes on
// the last item either way.
{
    _x params ["_name", "_why"];
    [_logic, _sortie, _name, false, _why] call FUNC(account);
} forEach _notLaunched;
