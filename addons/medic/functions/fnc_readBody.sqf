#include "script_component.hpp"
/*
 * Author: JMSB
 * The patient page's body table: per body part, open and bandaged wounds,
 * whether it is bleeding, a tourniquet, a fracture or splint, and the IVs
 * running into it.
 *
 * ACE's wound stores are hashmaps of part -> wounds since 3.16 and flat arrays
 * before it; both are read. ACM keeps its own IV bags (a hashmap of part ->
 * bags) and its own SAM splints; ACE's IV bags are read when ACM is absent.
 * All of them are published by their owner.
 *
 * BONE SAYS BOTH FACTS. A SAM splint (applied, or wrapped) and ACE's fracture
 * state are separate: a splinted limb whose fracture has not been set reads
 * FX + SAM. It is hot only for a fracture with nothing on it.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Six entries, head to right leg: [label, open, bandaged, bleeding, tourniquet, bone, ivs, bone hot] <ARRAY>
 *
 * Example:
 * [_unit] call jmfsb_medic_fnc_readBody
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _open = _unit getVariable [ACEV_OPEN_WOUNDS, createHashMap];
private _bandaged = _unit getVariable [ACEV_BANDAGED_WOUNDS, createHashMap];
private _tourniquets = _unit getVariable [ACEV_TOURNIQUETS, [0, 0, 0, 0, 0, 0]];
private _fractures = _unit getVariable [ACEV_FRACTURES, [0, 0, 0, 0, 0, 0]];
private _splints = _unit getVariable [ACMV_SPLINTS, [0, 0, 0, 0, 0, 0]];
private _acmBags = _unit getVariable [ACMV_IV_BAGS, createHashMap];
private _aceBags = _unit getVariable [ACEV_IV_BAGS, []];

// [count, bleeding] of one part's wounds, in either store shape.
private _fnc_wounds = {
    params ["_store", "_part", "_index"];
    private _list = [];
    if (_store isEqualType createHashMap) then {
        _list = (_store getOrDefault [_part, []]) apply {[_x param [1, 0], _x param [2, 0]]};
    } else {
        if (_store isEqualType []) then {
            _list = (_store select {(_x param [1, -1]) isEqualTo _index}) apply {[_x param [2, 0], _x param [3, 0]]};
        };
    };
    private _count = 0;
    private _bleeding = false;
    {
        _x params ["_amount", "_rate"];
        _count = _count + ceil _amount;
        if (_amount > 0 && _rate > 0) then {_bleeding = true};
    } forEach _list;
    [_count, _bleeding]
};

private _out = [];
{
    // The part's index, kept: the IV loops below have their own _forEachIndex.
    private _part = _x;
    private _i = _forEachIndex;
    ([_open, _part, _i] call _fnc_wounds) params ["_openCount", "_bleeding"];
    ([_bandaged, _part, _i] call _fnc_wounds) params ["_bandagedCount"];

    private _fracture = _fractures param [_i, 0];
    private _splint = _splints param [_i, SPLINT_NONE];
    if !(_splint isEqualType 0) then {_splint = SPLINT_NONE};
    private _unset = _fracture isEqualTo FRACTURE_UNSET;
    private _bone = switch (true) do {
        case (_splint > SPLINT_NONE && _unset): {["FX + SAM", "FX + SAM WRAP"] select (_splint >= SPLINT_WRAPPED)};
        case (_splint > SPLINT_NONE): {["SAM SPLINT", "SAM WRAPPED"] select (_splint >= SPLINT_WRAPPED)};
        case (_unset): {"FRACTURE"};
        case (_fracture isEqualTo FRACTURE_SET): {"SPLINTED"};
        default {""};
    };

    // IVs running - bags with fluid left in them
    private _ivs = [];
    if (_acmBags isEqualType createHashMap) then {
        {
            _x params [["_type", ""], ["_left", 0]];
            if (_left > 0) then {_ivs pushBack format ["%1 %2", toUpper _type, round _left]};
        } forEach (_acmBags getOrDefault [_part, []]);
    };
    if (_aceBags isEqualType []) then {
        {
            _x params [["_left", 0], ["_type", ""], ["_bagPart", -1]];
            if (_bagPart isEqualTo _i && _left > 0) then {_ivs pushBack format ["%1 %2", toUpper _type, round _left]};
        } forEach _aceBags;
    };

    _out pushBack [
        BODY_LABELS select _i,
        _openCount,
        _bandagedCount,
        _bleeding,
        (_tourniquets param [_i, 0]) isNotEqualTo 0,
        _bone,
        _ivs,
        _unset && _splint isEqualTo SPLINT_NONE
    ];
} forEach BODY_PARTS;

_out
