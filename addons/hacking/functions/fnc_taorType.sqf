#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_taorType

Description:
    What kind of war is being fought where this hack happened - "invasion",
    "occupation", "asymmetric", or "" for nowhere.

    THIS IS WHAT SCOPES THE PRODUCT MENU. A hack inside a conventional
    commander's ground finds air defence, coastal batteries, radars and
    artillery; one inside an asymmetric commander's ground finds leaders and
    installations. The hack tells you what kind of war you are in, and a menu
    that offered both everywhere told you nothing.

    NO MODULE, NO SETTING. ALiVE's OPCOM already says this - `controltype` on
    the instance, read by EFUNC(adapter_alive,commanders) - and its placement
    modules already say where each commander's ground is, read by
    EFUNC(adapter_alive,taorFor). Asking a mission maker to draw the same
    boundary a second time is how the two answers start to disagree.

    AN EXPLICIT TAOR BEATS AN IMPLICIT ONE. A commander with no taor markers
    owns the whole map minus its blacklist, which is ALiVE's own convention -
    so on a map with one conventional commander (no markers) and one asymmetric
    commander (markers round three towns), a hack in one of those towns has to
    answer "asymmetric". The explicit matches are taken first for exactly that.

Parameters:
    0: Position <ARRAY>

Returns:
    STRING - controltype, or "" when no commander holds this ground.

Example:
    private _type = [getPosATL player] call jmfsb_hacking_fnc_taorType

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_pos", [], [[]]]];

if (_pos isEqualTo []) exitWith {""};
// No commanders to scope by - not loaded, or loaded with none once the adapter
// has given up (user, 2026-11-02: "same as not loaded").
if (isNil QEFUNC(adapter_alive,commanders) || {!([] call EFUNC(common,aliveLoaded))}) exitWith {""};

private _explicit = "";
private _implicit = "";

{
    _x params ["_side", "_type"];

    ([_side] call EFUNC(adapter_alive,taorFor)) params [["_taor", []], ["_black", []]];

    // Blacklisted ground belongs to nobody, whatever else covers it.
    if ((_black findIf {_pos inArea _x}) > -1) then {continue};

    if (_taor isEqualTo []) then {
        // The whole map minus the blacklist. Held back in case something
        // explicit covers this spot.
        if (_implicit isEqualTo "") then {_implicit = _type};
        continue;
    };

    if ((_taor findIf {_pos inArea _x}) > -1) exitWith {_explicit = _type};
} forEach (call EFUNC(adapter_alive,commanders));

[_implicit, _explicit] select (_explicit isNotEqualTo "")
