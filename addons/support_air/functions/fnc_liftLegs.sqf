#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the transport task a lift card asks for and the point it flies to
 * first (2026-11-01, DESIGN_SUPPORT_MESSAGING step 7) - FUNC(liftThread) for a
 * new thread, FUNC(liftReply) for a NEXT LIFT in one:
 *
 *   `hlz`      PICKUP > LZ at the Pickup line (D4; none - the issuer's
 *              position); no LZ: "NO TARGET LOCATION"
 *   `casevac`  PICKUP at the pickup site; none: "NO TARGET LOCATION"
 *   `airdrop`  PARADROP over the drop point; none: "NO TARGET LOCATION"; a
 *              module that does not offer it: "CANNOT PARADROP"
 *   `extract`  EXTRACTION (user, 2026-11-02): EXTRACT at the pickup HLZ - a
 *              low hover there, home base after the ALL IN (2026-11-08). No
 *              pickup: "NO TARGET LOCATION"
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The order (EFUNC(support,readOrder)) <HASHMAP>
 * 2: The issuer <OBJECT>
 *
 * Return Value:
 * [task, first point, why - "" when it can] <ARRAY>
 *
 * Example:
 * [_logic, _order, _issuer] call jmfsb_support_air_fnc_liftLegs
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_order", createHashMap, [createHashMap]], ["_issuer", objNull, [objNull]]];

switch (_order getOrDefault ["kind", ""]) do {
    // THE PICKUP alone (user, 2026-11-08): its Pickup line, else the sender -
    // flown as the PICKUP > LZ's first leg with no LZ yet; the INSERTION
    // filed in its thread gives the LZ (FUNC(liftReply)).
    case ORDER_PICKUP: {
        private _pickup = _order getOrDefault ["pickup", []];
        if (_pickup isEqualTo []) then {
            (getPosATL _issuer) params ["_ix", "_iy"];
            _pickup = [_ix, _iy, 0];
        };
        [TASK_LIFT, _pickup, ""]
    };
    case ORDER_LIFT: {
        if ((_order getOrDefault ["lz", []]) isEqualTo []) exitWith {["", [], WHY_NO_TARGET]};
        private _pickup = _order getOrDefault ["pickup", []];
        if (_pickup isEqualTo []) then {
            (getPosATL _issuer) params ["_ix", "_iy"];
            _pickup = [_ix, _iy, 0];
        };
        [TASK_LIFT, _pickup, ""]
    };
    case ORDER_CASEVAC: {
        private _pickup = _order getOrDefault ["pickup", []];
        if (_pickup isEqualTo []) exitWith {["", [], WHY_NO_TARGET]};
        [TASK_PICKUP, _pickup, ""]
    };
    case ORDER_DROP: {
        private _point = _order getOrDefault ["point", []];
        if (_point isEqualTo []) exitWith {["", [], WHY_NO_TARGET]};
        private _offered = ([format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], [_logic] call FUNC(entityRow)] call FUNC(tasks)) apply {_x select 0};
        if !(TASK_PARADROP in _offered) exitWith {["", [], WHY_NO_PARADROP]};
        [TASK_PARADROP, _point, ""]
    };
    case ORDER_EXTRACT: {
        private _pickup = _order getOrDefault ["pickup", []];
        if (_pickup isEqualTo []) exitWith {["", [], WHY_NO_TARGET]};
        [TASK_EXTRACT, _pickup, ""]
    };
    default {["", [], WHY_NO_TARGET]};
}
