#include "script_component.hpp"
/*
 * Author: YonV
 * Server PFH: drop dead and hacked emitters from the jammer list, clean up their
 * debug markers, and re-broadcast. A zone dies with its emitter - destroyed OR
 * hacked, either one - which is what lets players silence a zone either loudly
 * or quietly.
 *
 * An abstract zone was born with no object - the temp flag records exactly that
 * - and nothing here can kill it: a temp zone deregisters itself when its
 * duration expires. It used to be tested with `isKindOf "Object"`, and
 * CfgVehicles' Object branch is map furniture - the terminal props are
 * Buildings - so every real emitter failed the test and the first tick threw
 * the whole registry away, temp zones included.
 *
 * Arguments (CBA PFH): unused
 *
 * Return Value: None
 *
 * Public: No
 */

if (isNil QGVAR(jammers)) exitWith {};

private _live = [];
{
    private _obj = _x param [ZONE_OBJ, objNull];
    private _keep = (_x param [ZONE_TEMP, false])
        || {!isNull _obj && {alive _obj} && {!(_obj getVariable [QEGVAR(hacking,hacked), false])}};

    if (_keep) then {
        _live pushBack _x;
        continue;
    };

    if (!isNull _obj) then {
        private _mkr = _obj getVariable [QGVAR(marker), ""];
        if (_mkr isNotEqualTo "") then { deleteMarker _mkr };
    };
} forEach GVAR(jammers);

if (count _live == count GVAR(jammers)) exitWith {};   // nothing died

GVAR(jammers) = _live;
[] call FUNC(publishZones);
