#include "script_component.hpp"
/*
 * Author: JMSB
 * The tasks ONE asset offers - the provider's "tasks" code. The types
 * declaration (SUPPORT_TYPES) is the shape for the type; this narrows and
 * fills it for the picked airframe:
 *
 *   CAS        ATTACK RUN and SAD get an ORDNANCE stepper listing THIS
 *              aircraft's stores, the row's field 5, AUTO first; DANGER
 *              CLOSE is offered only while the module's Friendly Range is
 *              above 0, and its map ring is that range
 *   TRANSPORT  only the tasks the module allows and the airframe can fly
 *   LOGISTICS  parachute or sling, as the module resolved it, and CONTENTS
 *              when the module names more than one load
 *   QRF        only the insertions the module allows and the aircraft can fly
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: The asset's row <ARRAY>
 *
 * Return Value:
 * Task declarations <ARRAY>
 *
 * Example:
 * ["air:0", _row] call jmfsb_support_air_fnc_tasks
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_row", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[]};

private _allowed = _logic getVariable [QGVAR(allowed), []];

switch (_logic getVariable [QGVAR(kind), ""]) do {
    case KIND_CAS: {
        // ORDNANCE on the two tasks that release - this airframe's own stores.
        // DANGER CLOSE only while the module holds releases near friendlies at
        // all, with the ring the map draws set to the module's own range.
        private _ord = _row param [5, []];
        if !(_ord isEqualType []) then {_ord = []};
        private _range = _logic getVariable [QGVAR(friendlyRange), 0];
        [DECL_SAD, DECL_LOITER, DECL_RUN] apply {
            private _decl = +_x;
            private _steps = (_decl select 4) select {_range > 0 || (_x select 1) isNotEqualTo SLOT_DANGER};
            _steps = _steps apply {
                if ((_x select 1) isEqualTo SLOT_DANGER) then {
                    private _s = +_x;
                    _s set [8, ["ring", _range]];
                    _s
                } else {_x};
            };
            if (count _ord > 1 && {(_decl select 0) in [TASK_RUN, TASK_SAD]}) then {
                _steps pushBack ["ORDNANCE", SLOT_ORDNANCE, 1, 0, count _ord - 1, _ord apply {toUpper _x}, [], false];
            };
            _decl set [4, _steps];
            _decl
        }
    };
    case KIND_TRANSPORT: {
        [DECL_PICKUP, DECL_LAND, DECL_LAND_OFF, DECL_MOVE, DECL_EXTRACT, DECL_LIFT, DECL_ORBIT, DECL_FASTROPE, DECL_HELOCAST, DECL_PARADROP, DECL_SLING] select {(_x select 0) in _allowed}
    };
    case KIND_LOGISTICS: {
        private _decl = +([DECL_DROP_CHUTE, DECL_DROP_SLING] select (_logic getVariable [QGVAR(sling), false]));
        // CONTENTS: one of the module's loads per drop, when it has more than
        // one ("magazines; itemsMedical").
        private _loads = _logic getVariable [QGVAR(loads), []];
        if (count _loads > 1) then {
            private _steps = +(_decl select 4);
            _steps pushBack ["CONTENTS", SLOT_CONTENTS, 1, 0, count _loads - 1, _loads apply {toUpper _x}, [], false];
            _decl set [4, _steps];
        };
        [_decl]
    };
    case KIND_QRF: {
        [DECL_STATIC, DECL_ASSAULT] select {(_x select 0) in _allowed}
    };
    default {[]};
}
