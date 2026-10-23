#include "script_component.hpp"

// THE LEDGER IS THE SERVER'S. A request is dispatched where it was made (the
// providers' own task code decides where the work runs), but a cooldown has
// to hold for every player on the side, so the client that got an accepted
// order sends the time here and the server publishes the whole ledger.
if (isServer) then {
    [QGVAR(cooldown), {
        params [["_assetId", "", [""]], ["_until", 0, [0]]];
        if (_assetId isEqualTo "") exitWith {};
        GVAR(readyAt) set [_assetId, _until];
        publicVariable QGVAR(readyAt);
        INFO_2("cooldown: %1 ready again at %2",_assetId,_until);
    }] call CBA_fnc_addEventHandler;
};
