#include "script_component.hpp"

// THE SERVER'S OWN LIST OF ZEUS UNITS (review S7). Units the mission gives a
// curator role (jmfsb_Player_Unit, set in their init, which has run on the
// server by now) go on it from the server's own copy, read once here - a
// client broadcasting a new role later changes nothing.
if (isServer) then {
    private _allowed = localNamespace getVariable [QGVAR(zeusAllowed), []];
    {
        private _role = _x getVariable [QEGVAR(Player,Unit), ""];
        if (_role isEqualType "" && {(toLower _role) in CURATOR_ROLES}) then {_allowed pushBackUnique _x};
    } forEach (allUnits + playableUnits + switchableUnits);
    localNamespace setVariable [QGVAR(zeusAllowed), _allowed];
};

if (hasInterface) then {
    [[player]] remoteExecCall [QFUNC(editableAdd), SERVER_OWNER];
};
