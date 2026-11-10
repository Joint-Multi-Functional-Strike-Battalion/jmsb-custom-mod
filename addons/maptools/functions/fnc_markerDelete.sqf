#include "script_component.hpp"
/*
 * Author: YonV
 * Deletes a marker this player owns - MARK's press on a marker, and the marker
 * card's DELETE (user, 2026-11-01: markers placed are deletable from the
 * tablet, as the game's map deletes them).
 *
 * A player marker of his own: a local one (MY MAP) is taken back locally and
 * off CLEAR's list, a sent one deleted for everyone, as the game's map does.
 * Anything else is asked of ALiVE's Advanced Markers, through
 * jmfsb_adapter_alive and only when it is loaded: one of his own there is
 * removed the way ALiVE removes it. Anybody else's marker is left alone.
 *
 * Arguments:
 * 0: Marker <STRING>
 *
 * Return Value:
 * It was deleted <BOOL>
 *
 * Example:
 * [_marker] call jmfsb_maptools_fnc_markerDelete
 *
 * Public: No
 */

params [["_marker", "", [""]]];

if (_marker isEqualTo "") exitWith {false};

if ([_marker] call FUNC(markerOwn)) exitWith {
    private _index = GVAR(marks) find _marker;
    if (_index < 0) then {
        deleteMarker _marker;
    } else {
        deleteMarkerLocal _marker;
        GVAR(marks) deleteAt _index;
    };
    true
};

if (isNil QEFUNC(adapter_alive,markerRemove)) exitWith {false};

[_marker] call EFUNC(adapter_alive,markerRemove)
