#include "script_component.hpp"
/*
    Author: YonV

    Description:
        THE PLATOON TABS, read from the mission. A tab is a view onto the same
        role list and nothing more - it changes which squads the tree draws and
        it changes nothing about who may take what. Grouping five squads under
        two headings is a visual for this screen (user, 2026-09-01); the roles,
        the conditions and the radio index all still come off
        Dynamic_Groups >> group_setup in the order that file writes them.

        NO Platoons CLASS MEANS NO TABS. A mission that does not declare one
        gets the flat list it has always had, tab row hidden, nothing moved.
        That is what every mission other than this one does.

        A TAB HAS TWO LINES NOW (user, 2026-09-03: "make the buttons double
        height to add second row to call signs"). "name" is the top line and
        says what kind of element it is - "1ST PLT INF", "C2" - and "callsign"
        is the word under it in bold, which is what anyone actually says on the
        radio. A tab with no callsign draws one line and looks like it always
        did, so a mission that never heard of the property is unaffected.

        TEN IS THE CAP, and it is a real limit rather than a suggestion: the
        tab row is ten controls in gui.hpp, FIVE to a row. Five across puts the
        whole task force on one row. An eleventh is dropped with a line in the
        RPT.

        A SQUAD IN NO TAB STILL APPEARS. If it did not, a role nobody can see
        is a role nobody can take, and the screen would lie about how many
        slots are open - the OPEN count is built off the whole of
        YMF_dynamicGroups, not off the visible tab. Loose squads get their own
        UNASSIGNED tab when there is room for one, and are folded into the last
        tab when there is not. Either way the RPT names them, because the fix
        is one line of config and the symptom otherwise is "why is Talon on
        2nd Platoon".

    Parameters:
        NONE

    Returns:
        ARRAY - [[tab label, [SQUAD NAMES, upper-cased], callsign], ...],
                [] for no tabs
*/

// The ORBAT - the database's when TAC//PAC holds one, else the mission's.
([] call FUNC(orbat)) params ["", "_platoonRows"];
if (_platoonRows isEqualTo []) exitWith {[]};

private _out = [];
private _over = [];

{
    _x params ["_id", "_label", "_callsign", "", "_squadsRaw"];
    private _squads = _squadsRaw apply {toUpper _x};

    // A tab with no name or no squads is a typo, and it says so - an empty tab
    // is indistinguishable from a squad that failed to load.
    if (_label isEqualTo "" || {_squads isEqualTo []}) then {
        WARNING_1("Platoons","tab '%1' has no name or no squads - skipped",_id);
        continue;
    };

    if (count _out >= MAX_PLT_TABS) then {
        _over pushBack _label;
        continue;
    };

    _out pushBack [toUpper _label, _squads, toUpper _callsign];
} forEach _platoonRows;

if (_over isNotEqualTo []) then {
    WARNING_2("Platoons","%1 tab(s) past the tenth were dropped: %2",count _over,_over joinString ", ");
};

if (_out isEqualTo []) exitWith {[]};

// ---------------------------------------------------------- the loose ones --
private _named = [];
{_named append (_x select 1)} forEach _out;

private _loose = (YMF_dynamicGroups apply {toUpper (_x select 0)}) select {!(_x in _named)};

if (_loose isNotEqualTo []) then {
    if (count _out < MAX_PLT_TABS) then {
        _out pushBack ["UNASSIGNED", _loose, ""];
        INFO_1("Platoons","%1 in no tab - shown under UNASSIGNED",_loose joinString ", ");
    } else {
        private _last = _out select (MAX_PLT_TABS - 1);
        _last set [1, (_last select 1) + _loose];
        INFO_2("Platoons","%1 in no tab and all tabs are taken - shown under %2",_loose joinString ", ",_last select 0);
    };
};

_out
