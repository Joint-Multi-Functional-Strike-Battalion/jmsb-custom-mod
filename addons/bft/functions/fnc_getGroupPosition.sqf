#include "script_component.hpp"
/*
 * Author: Jacco Douma, JMSB
 * Where a group's marker goes this pass. Two independent stages: tracking says
 * where the group IS - the leader, or a weighted average pulled towards the rest
 * of the group - and trailing says how far behind that truth the marker is
 * allowed to lag, which is what makes a tracker feel like a radio report rather
 * than a live feed.
 *
 * Recent positions are kept on the group itself and never broadcast: each
 * machine builds the same history off the same leader positions, so the trail
 * costs nothing on the network.
 *
 * Every position is the man's GPS one (jmfsb_ew_fnc_gpsOf, when EW is
 * loaded): a group whose GPS is spoofed is tracked where its sets say it is.
 * A man whose GPS is denied still counts at his true position - the group
 * marker never vanishes because one set lost its lock.
 *
 * Arguments:
 * 0: Group <GROUP>
 *
 * Return Value:
 * Position <ARRAY>
 *
 * Example:
 * [group player] call jmfsb_bft_fnc_getGroupPosition
 *
 * Public: No
 */

params ["_group"];

private _ew = !isNil QEFUNC(ew,gpsOf);
private _fnc_at = {
    params ["_unit"];
    private _at = position _unit;
    if (_ew) then {
        private _offset = ([_unit] call EFUNC(ew,gpsOf)) select 1;
        _at = _at vectorAdd [_offset select 0, _offset select 1, 0];
    };
    _at
};

private _fnc_weightedAverage = {
    params ["_group"];

    private _position = [leader _group] call _fnc_at;
    // Starting weight: the number of times the leader's own position counts, so
    // a straggler cannot drag the marker off the body of the group.
    private _weight = 3 * (count units _group);

    {
        // Anyone more than 500m out is not with the group any more.
        if ((_x distance2D (leader _group)) > 500) then {continue};

        // The leader is already in the running average.
        if (_x isEqualTo leader _group) then {continue};

        // Each unit pulls the marker towards itself, less and less as the
        // running total grows.
        _position = [
            (((_position select 0) * _weight) + (([_x] call _fnc_at) select 0)) / (_weight + 1),
            (((_position select 1) * _weight) + (([_x] call _fnc_at) select 1)) / (_weight + 1)
        ];

        _weight = _weight + 1;
    } forEach units _group;

    _position
};

private _position = [leader _group] call _fnc_at;

switch (GVAR(trackingMode)) do {
    case "weightedAverage": {
        _position = [_group] call _fnc_weightedAverage;
    };
};

// Push onto the group's history, newest first, capped at the trailing count.
private _positions = _group getVariable [QGVAR(trail), []];
_positions = [_position] + _positions;
_positions = _positions select [0, round GVAR(trailingCount)];
_group setVariable [QGVAR(trail), _positions];

switch (GVAR(trailingMode)) do {
    case "weightedAverage": {
        private _weight = 1;
        private _totalWeight = 1;
        _position = +(_positions select 0);
        {
            // The newest position is the one being weighted against.
            if (_forEachIndex isEqualTo 0) then {continue};
            _weight = _weight * GVAR(trailingWeight);

            _position = [
                (((_position select 0) * _totalWeight) + ((_x select 0) * _weight)) / (_totalWeight + _weight),
                (((_position select 1) * _totalWeight) + ((_x select 1) * _weight)) / (_totalWeight + _weight)
            ];

            _totalWeight = _totalWeight + _weight;
        } forEach _positions;
    };
    case "delayed": {
        _position = _positions select -1;
    };
};

_position
