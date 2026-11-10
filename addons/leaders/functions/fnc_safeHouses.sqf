#include "script_component.hpp"
/*
 * Author: YonV
 * The chain's ground: enterable buildings in settlement clusters inside the
 * asymmetric commander's TAOR.
 *
 * IN ADDITION to ALiVE's own installations, which join the intel pool
 * separately - the network is the sheds AND the houses, and a player who only
 * ever hits installations never finds anybody.
 *
 * Arguments: None
 *
 * Return Value:
 * Buildings <ARRAY of OBJECT>
 *
 * Public: No
 */

// The module's own TAOR field wins; the commander's ALiVE placements
// otherwise (without ALiVE, the jmfsb_taor markers - EFUNC(common,groundFor)). And whichever ground was resolved goes in the LOG - an empty
// list here means every settlement on the map is a candidate, which on a
// shared map is leaders standing on somebody else's ground, and that state
// has to be readable in the RPT rather than deduced from where a body fell.
private _taor = [];
private _black = [];
if (!isNil QGVAR(taorMarkers) && {GVAR(taorMarkers) isNotEqualTo []}) then {
    _taor = +GVAR(taorMarkers);
} else {
    ([GVAR(asymSide)] call EFUNC(common,groundFor)) params ["_t", "_b"];
    _taor = _t;
    _black = _b;
};
if (_taor isEqualTo []) then {
    WARNING_1("no TAOR resolved for %1 - safe houses will come from the WHOLE MAP; set the module's TAOR Markers field to pin the chain down",GVAR(asymSide));
} else {
    INFO_2("safe-house ground for %1: %2",GVAR(asymSide),_taor joinString ", ");
};

// ALiVE's settlement clusters, or without ALiVE the map's own towns.
private _clusters = call EFUNC(common,settlements);
if (_clusters isEqualTo []) exitWith {
    INFO("no settlement clusters - map unindexed, so no safe houses");
    []
};

private _houses = [];
{
    _x params ["_cpos", "_csize"];
    if (_taor isNotEqualTo [] && {(_taor findIf {_cpos inArea _x}) < 0}) then {continue};
    if ((_black findIf {_cpos inArea _x}) > -1) then {continue};

    {
        private _b = _x;

        // THE HOUSE HAS TO BE IN THE TAOR, not just the cluster it sits in.
        // The search reaches the cluster's own radius out from its centre, so
        // a settlement on a boundary was handing out safe houses on ground the
        // asymmetric commander does not operate on - and a leader who hides
        // outside his own commander's area is not hiding among his own people,
        // which is the whole idea.
        if (_taor isNotEqualTo [] && {(_taor findIf {_b inArea _x}) < 0}) then {continue};
        if ((_black findIf {_b inArea _x}) > -1) then {continue};

        // Three positions or more: somewhere a man can actually be, rather
        // than a shed he would stand on top of.
        if (count (_b buildingPos -1) >= 3 && {damage _b < 0.5}) then {
            _houses pushBackUnique _b;
        };
    } forEach (nearestObjects [_cpos, ["House"], _csize max 150]);
} forEach _clusters;

_houses
