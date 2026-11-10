#include "script_component.hpp"
/*
 * Author: YonV
 * Whether one order may go to this asset, where to and what - the ONE check
 * the requester's machine (FUNC(task)), the verdict before CONFIRM
 * (FUNC(preview)) and the server (FUNC(order)) all run. The server runs it
 * again with the sender's own unit, because a client can call the server
 * without passing FUNC(task) (review S6).
 *
 * WHAT IS CHECKED: the side's own asset; idle and not spent (FUNC(available));
 * a method this asset offers; a delivery point (required - there is no
 * "on me"); a cart with something in it (FUNC(readCart)), no more items than
 * the Capacity - one for a SLING LOAD the module flies with one helicopter -
 * and, for a SLING LOAD, every item one this hook can lift.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Task token, or "rtb" <STRING>
 * 2: Delivery point, [] for none <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 * 4: The requester <OBJECT>
 *
 * Return Value:
 * 0: May be flown <BOOL>
 * 1: Why not, "" when it may <STRING>
 * 2: The delivery point, [x, y, 0], [] for a recall <ARRAY>
 * 3: The cart, [[catalog index, count], ...], [] for a recall <ARRAY>
 *
 * Example:
 * [_logic, "AIRDROP", _pos, [], player] call jmfsb_support_logistics_fnc_check
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]], ["_unit", objNull, [objNull]]];

if (isNull _logic) exitWith {[false, "that asset is gone", [], []]};

private _callsign = _logic getVariable [QGVAR(callsign), DEF_CALLSIGN];

// The side's own assets only - the board lists no other (FUNC(assets)), but
// a request can come from anywhere.
if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group _unit)) exitWith {
    [false, format ["%1 is not your side's asset", _callsign], [], []]
};

// RECALL IS PASSED THROUGH WHENEVER SOMETHING IS OUT - an asset you want home
// is busy.
if (_task isEqualTo TASK_RTB) exitWith {
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_IDLE) exitWith {
        [false, format ["%1 has nothing out to recall", _callsign], [], []]
    };
    [true, "", [], []]
};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[false, _why, [], []]};

// The token must be one THIS asset offers - the screen only shows those, but
// a request can come from anywhere.
private _offered = ([format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], []] call FUNC(tasks)) apply {_x select 0};
if !(_task in _offered) exitWith {
    INFO_3("check: refused for %1 - '%2' is not one of %3",_callsign,_task,_offered);
    [false, format ["%1 does not fly %2", _callsign, _task], [], []]
};

if (count _pos < 2) exitWith {[false, "no delivery point", [], []]};
_pos = [_pos param [0, 0, [0]], _pos param [1, 0, [0]], 0];

private _sling = _task isEqualTo TASK_SLING;
private _cap = _logic getVariable [QGVAR(capacity), DEF_CAPACITY];
if (_sling && !(_logic getVariable [QGVAR(slingEach), true])) then {_cap = 1};

private _catalog = _logic getVariable [QGVAR(catalog), []];
private _cart = [_prm, _catalog, _cap] call FUNC(readCart);
if (_cart isEqualTo []) exitWith {[false, "nothing ordered", [], []]};

private _total = 0;
{_total = _total + (_x select 1)} forEach _cart;
if (_total > _cap) exitWith {
    [false, format ["%1 takes %2 at most - %3 ordered", _callsign, _cap, _total], [], []]
};

if (_sling) then {
    private _hookMass = _logic getVariable [QGVAR(hookMass), 0];
    {
        private _item = _catalog select (_x select 0);
        if !(_item select ITEM_HOOK) exitWith {
            _why = format ["%1 cannot go on a hook", _item select ITEM_NAME];
        };
        if ((_item select ITEM_MASS) > _hookMass) exitWith {
            _why = format ["%1 is too heavy for the hook - %2 kg, %3 kg at most", _item select ITEM_NAME, round (_item select ITEM_MASS), round _hookMass];
        };
    } forEach _cart;
};
if (_why isNotEqualTo "") exitWith {[false, _why, [], []]};

[true, "", _pos, _cart]
