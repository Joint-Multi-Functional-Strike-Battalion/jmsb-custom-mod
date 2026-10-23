#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_scanDevices

Description:
    Everything hackable within reach, as one list for the tablet: comm towers and
    EW emitters, live enemy drones, downed ones, and enemy soldiers. Each kind
    keeps its own range, so a wreck you must stand over and a soldier 800 m away
    can sit on the same screen without pretending they are the same thing.

    Sorted nearest first and capped at the number of cards the screen has - if
    there are more devices than slots, the far ones are the ones you cannot see,
    which is the right way round.

Parameters:
    _unit : OBJECT - the operator.

Returns:
    ARRAY - [[_object, _kind, _label, _distance, _range], ...]
            _kind is "tower" | "drone" | "wreck" | "unit".
            A "unit" is a net: a man's handset, or a crewed vehicle that RF
            says carries a set (GVAR(rfReach)) - its crew's net.

Author:
    JMSB
---------------------------------------------------------------------------- */
params ["_unit"];

private _out = [];

// --- towers and EW emitters ------------------------------------------------
private _towerRange = [QGVAR(cfg_hack_range)] call FUNC(hackSetting);
private _cd = [QGVAR(cfg_hack_cooldown)] call FUNC(hackSetting);
{
    private _t = _x;
    private _last = _t getVariable [QGVAR(lastHack), -1e9];
    private _spent = (_cd < 0 && {_last > -1e8}) || {_cd >= 0 && {(CBA_missionTime - _last) < _cd}};
    _out pushBack [
        _t, "tower",
        ["COMM TOWER", "SPENT"] select _spent,
        _unit distance _t, _towerRange
    ];
} forEach ([_unit, _towerRange + TAB_SCAN_PAD] call FUNC(towersInRange));

// --- drones ---------------------------------------------------------------
private _drone = [_unit] call FUNC(nearestDrone);
if (!isNull _drone) then {
    _out pushBack [_drone, "drone", "HOSTILE UAV", _unit distance _drone, HACK_DRONE_RANGE];
};

// --- downed drones ---------------------------------------------------------
// A wreck is a separate kind, not a drone that happens to be dead: there is
// nothing left to take down, but there is still a data card to pull.
private _wreck = [_unit] call FUNC(nearestWreck);
if (!isNull _wreck) then {
    _out pushBack [_wreck, "wreck", "DOWNED UAV", _unit distance _wreck, HACK_WRECK_RANGE];
};

// --- cell phones, only while remote hacking is on --------------------------
// Not every soldier: only the percentage who actually carry a phone
// (FUNC(hasPhone), derived per man). The rest have nothing to hack.
//
// WHOSE NETS ARE FAIR GAME IS A SETTING. It was hostile-only, which is the
// obvious rule and the wrong one for half the missions this gets played on: in
// an insurgency the phone worth listening to belongs to somebody who is not
// shooting at you, and on a two-sided exercise the point may be to listen to the
// other half of your own force. See GVAR(netTargets).
//
// YOUR OWN GROUP IS NEVER ON THE LIST, whatever the setting says. Breaking into
// the net you are already on is not intelligence, and the men standing next to
// you would otherwise be the nearest handsets on the screen every time.
if (missionNamespace getVariable [QGVAR(remoteHackEnabled), false]) then {
    private _range = missionNamespace getVariable [QGVAR(rh_max_range), RH_RANGE_DEF];
    private _mySide = side group _unit;
    private _scope = GVAR(netTargets);
    private _myGroup = group _unit;
    // ONE ENTRY PER GROUP, NOT PER MAN. A section standing together filled the
    // whole list with its own riflemen - rows saying CELL PHONE at 218, 219 and
    // 222 m - and pushed every other device off the card list. You are breaking
    // into a net, and a net is a group; the nearest handset on it is the way
    // in, so that is the one the entry carries.
    private _byGroup = createHashMap;
    {
        private _theirSide = side group _x;
        private _hostile = _theirSide getFriend _mySide < 0.6;
        private _civ = _theirSide isEqualTo civilian;

        private _inScope = switch (_scope) do {
            case 1: {_hostile || _civ};
            case 2: {true};
            default {_hostile && {!_civ}};
        };

        if (
            alive _x && {isNull objectParent _x}
            && {(group _x) isNotEqualTo _myGroup}
            && _inScope
            && {!(_x getVariable [QGVAR(hacked), false])}
            && {[_x] call FUNC(hasPhone)}
        ) then {
            private _grp = group _x;
            private _d = _unit distance _x;
            private _best = _byGroup getOrDefault [str _grp, []];
            if (_best isEqualTo [] || {_d < (_best select 1)}) then {
                _byGroup set [str _grp, [_x, _d, _grp]];
            };
        };
    } forEach (_unit nearEntities ["Man", _range]);

    // A VEHICLE CARRYING A SET is a net too - its crew's - when RF says the
    // operator's set hears it (GVAR(rfReach), the server's answer while the
    // HACK board is open). A crew whose net already has a handset listed
    // keeps that entry. Same reach, same scope, never your own group.
    {
        _x params [["_holder", objNull, [objNull]]];
        if (isNull _holder || _holder isKindOf "CAManBase" || !alive _holder) then {continue};
        private _boss = effectiveCommander _holder;
        if (isNull _boss || !alive _boss) then {continue};
        private _grp = group _boss;
        private _theirSide = side _grp;
        private _hostile = _theirSide getFriend _mySide < 0.6;
        private _civ = _theirSide isEqualTo civilian;
        private _inScope = switch (_scope) do {
            case 1: {_hostile || _civ};
            case 2: {true};
            default {_hostile && !_civ};
        };
        private _d = _unit distance _holder;
        if (!_inScope || _grp isEqualTo _myGroup || _d > _range || (str _grp) in _byGroup) then {continue};
        _byGroup set [str _grp, [_holder, _d, _grp]];
    } forEach GVAR(rfReach);

    {
        _y params ["_man", "_d", "_grp"];
        // A net already broken is not offered a second time.
        if (_grp getVariable [QGVAR(hacked), false]) then {continue};
        // A NET THAT IS NOT HOSTILE SAYS SO. Spending a minute and a detection
        // roll to break into your own side's traffic because the row looked
        // like every other row is the mistake this label exists to prevent.
        private _flag = ["", " (FRIENDLY)"] select ((side _grp) getFriend _mySide >= 0.6);
        _out pushBack [_man, "unit", format ["NET - %1%2", groupId _grp, _flag], _d, _range];
    } forEach _byGroup;
};

private _ranked = _out apply { [_x select 3, _x] };
_ranked sort true;
_out = _ranked apply { _x select 1 };

if (count _out > TAB_CARDS) then { _out = _out select [0, TAB_CARDS] };
_out
