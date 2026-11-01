#include "script_component.hpp"

[] call FUNC(arsenal_postInit);

// No clearAllCargo / clearCargoBackpacks CBA events (review R1): any client
// could raise them to empty any container on the map. The machine moving the
// pack clears it with global commands (FUNC(clearAllCargo)).

if (isServer) then {
    // Once, here (review R1): it was added on a CBA event any client could
    // raise, a duplicate handler on every raise.
    addMissionEventHandler ["HandleDisconnect", FUNC(EHHandleDisconnect)];

    // PFH to check when the helper object _ropeTop and the WeaponHolderSimulated
    // holding the backpack have landed
    [QGVAR(checkLandedPFH), {
        params [["_ropeTop", objNull, [objNull]], ["_holder", objNull, [objNull]]];
        // A CBA event carries no sender, so the objects are checked: only the
        // rope-top helper is ever deleted and only a ground weapon holder is
        // ever moved - not whatever object a client names (review S7).
        if (typeOf _ropeTop isNotEqualTo ROPE_TOP_CLASS) exitWith {};
        if !(_holder isKindOf "WeaponHolderSimulated" || {_holder isKindOf "GroundWeaponHolder"}) then {_holder = objNull};
        [{
            params ["_ropeTop", "_pfhID"];
            if (speed _ropeTop < 1 && {((getPos _ropeTop) select 2) < 1}) exitWith {
                deleteVehicle _ropeTop;
                [_pfhID] call CBA_fnc_removePerFrameHandler;
            };
        }, 0, _ropeTop] call CBA_fnc_addPerFrameHandler;
        [{
            params ["_holder", "_pfhID"];
            if (speed _holder < 1 && {getPos _holder # 2 < 1}) exitWith {
                private _pos = getPos _holder;
                _pos set [2, 0];
                _holder setPos _pos;
                [_pfhID] call CBA_fnc_removePerFrameHandler;
            };
        }, 0, _holder] call CBA_fnc_addPerFrameHandler;
    }] call CBA_fnc_addEventHandler;
};

GVAR(isACEAXLoaded) = isClass (configFile >> "CfgPatches" >> "aceax_gearinfo");

// Backpack classnames which will be made invisible instead of being made a chestpack. Useful for items like the vanilla legstrap.
GVAR(exceptions) = [
    "B_LegStrapBag_black_F",
    "B_LegStrapBag_coyote_F",
    "B_LegStrapBag_olive_F",
    "rhs_medic_bag"
];
