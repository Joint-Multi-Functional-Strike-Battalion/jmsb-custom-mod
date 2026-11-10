#include "script_component.hpp"
/*
 * Author: YonV
 * Takes back every patrol nobody is near any more.
 *
 * THE OTHER HALF OF THE PROXIMITY RULE. FUNC(topUp) will not put a drone up
 * over ground with no player within UAS_PLAYER_RANGE; without this, one that
 * was up when the section drove away stays up forever - the fleet would only
 * ever grow, and the mission would still be flying twenty airframes over an
 * empty island an hour later.
 *
 * MEASURED TO THE ORBIT CENTRE the patrol was given, not to where the airframe
 * happens to be on its circle - see UAS_PLAYER_RANGE. A patrol with no centre
 * recorded (an airframe put up by a build older than this) is left alone
 * rather than deleted on a guess.
 *
 * THE HUSK IS FLAGGED BEFORE IT GOES, so the Deleted handler FUNC(topUp) put
 * on it knows the removal was ours and stays quiet. A drone taken back on
 * purpose is not "DELETED WHILE STILL FLYING" - that warning is for a script
 * or a garbage collector eating live patrols and is worth keeping loud.
 *
 * Arguments: None
 *
 * Return Value:
 * How many were taken back <NUMBER>
 *
 * Example:
 * call jmfsb_uas_fnc_standDown
 *
 * Public: No
 */

if (!isServer) exitWith {0};

private _gone = 0;

{
    private _key = _x;
    private _list = GVAR(patrols) getOrDefault [_key, []];
    if (_list isEqualTo []) then {continue};

    private _kept = _list select {
        !isNull _x && {alive _x} && {
            private _orbit = _x getVariable [QGVAR(orbit), []];

            // NOTHING VANISHES IN FRONT OF ANYBODY. The orbit centre is the
            // rule, but a patrol on the near side of a circle whose centre has
            // just gone out of range is still a real aircraft in somebody's
            // sky - and an aircraft that pops out of existence while it is
            // being watched is worse than one that should not have been there.
            // It goes on a later tick, when it has flown on or they have.
            _orbit isEqualTo []
                || {[_orbit] call FUNC(playerNear)}
                || {[getPosATL _x, UAS_SEEN_RANGE] call FUNC(playerNear)}
        }
    };

    // What is left over and still flying is what nobody is near. The dead and
    // the null are simply dropped from the ledger, which is FUNC(livePatrols)'
    // own pruning done a tick early - and they are NOT counted below, because
    // a drone somebody shot down is attrition and attrition comes back as a
    // drip. Only the ones this function retired are given back.
    private _took = 0;

    {
        if (isNull _x || {!alive _x} || {_x in _kept}) then {continue};

        INFO_3("patrol stood down: %1 at %2 - no player within %3 m",typeOf _x,mapGridPosition _x,UAS_PLAYER_RANGE);
        _x setVariable [QGVAR(retired), true];
        {deleteVehicle _x} forEach (crew _x);
        deleteVehicle _x;
        _took = _took + 1;
    } forEach _list;

    GVAR(patrols) set [_key, _kept];
    _gone = _gone + _took;

    // NO CREDIT TO HAND BACK ANY MORE. Replacement used to be a drip against a
    // shared per-side ceiling, and a stand-down had to return what it retired or
    // ground emptied by a section moving on would refill at one airframe a
    // minute. A patrol is filled to its own module's number every tick now, so
    // ground that empties refills as soon as somebody is near it again and
    // there is nothing to keep score of.
} forEach (keys GVAR(patrols));

_gone
