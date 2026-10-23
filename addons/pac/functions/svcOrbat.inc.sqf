// THE ORDER OF BATTLE, read between the settings and the rest of the sections.
//
// It has to be here and not with the others: "currentOrbat" comes out of the
// settings above, and the ORBAT itself names the messaging nets and the radio
// plan it wants - so both have to be known before any section a version setting
// can steer is fetched. Included rather than inlined only to keep
// FUNC(svcStructure)'s two section loops next to each other and readable.
// the ORBAT document. A unit may keep more than one - <unit>.orbat.<id> -
// and the "currentOrbat" setting names which this mission wants; empty means
// the common one. Same arrangement as currentOpord picking an order.
private _orbatKey = _unit + ".orbat";
private _wantOrbat = _settings getOrDefault ["currentOrbat", ""];
if (_wantOrbat isEqualType "" && _wantOrbat isNotEqualTo "") then {
    _orbatKey = _unit + ".orbat." + _wantOrbat;
};
([_orbatKey] call _fnc_fetch) params ["_odoc", "_ostatus"];
// A named ORBAT that is not there falls back to the common one rather than
// leaving the mission with no order of battle at all.
if (_ostatus isNotEqualTo "ok" && _orbatKey isNotEqualTo (_unit + ".orbat")) then {
    ([_unit + ".orbat"] call _fnc_fetch) params ["_odoc", "_ostatus"];
};
if (_ostatus isEqualTo "error") exitWith {[createHashMap, "error"]};
if (_ostatus isEqualTo "ok") then {
    private _g = _odoc getOrDefault ["groups", []];
    private _p = _odoc getOrDefault ["platoons", []];
    private _f = _odoc getOrDefault ["faction", ""];
    private _s = _odoc getOrDefault ["side", ""];
    if (_g isEqualType [] && _p isEqualType []) then {
        if !(_f isEqualType "") then {_f = ""};
        // The side the unit fights on (2026-09-09). Absent means unsaid, and
        // jmfsb_groups_fnc_orbat answers WEST for that - what every caller
        // assumed before the field existed.
        if !(_s isEqualType "") then {_s = ""};
        _structure set ["orbat", createHashMapFromArray [["groups", _g], ["platoons", _p], ["faction", _f], ["side", _s]]];
        _found = _found + 1;
    };

    // AN ORDER OF BATTLE NAMES ITS OWN COMMS (2026-09-09). A comms plan is
    // written around squads, so a different order of battle usually wants a
    // different one - and having to remember to change two settings together
    // is how a night starts with everybody on the wrong channel. The ORBAT
    // carries the two names; they are folded into the settings here, BEFORE the
    // sections are fetched, so the fetch picks them up like any other version.
    //
    // The mission still wins: settings it declares are restored in
    // FUNC(structureAdopt), which is the whole point of that check.
    {
        _x params ["_field", "_setting"];
        private _want = _odoc getOrDefault [_field, ""];
        if (_want isEqualType "" && _want isNotEqualTo "") then {
            _settings set [_setting, _want];
            INFO_2("the order of battle names its %1: %2",_field,_want);
        };
    } forEach [
        ["netsVersion",      "currentNets"],
        ["radioVersion",     "currentRadio"],
        // AND ITS GEAR (2026-09-09). A tropical order of battle draws a
        // tropical arsenal; asking somebody to remember a second setting is how
        // the wrong one gets used.
        ["arsenalVersion",   "currentArsenal"],
        ["motorpoolVersion", "currentMotorpool"]
    ];
};

