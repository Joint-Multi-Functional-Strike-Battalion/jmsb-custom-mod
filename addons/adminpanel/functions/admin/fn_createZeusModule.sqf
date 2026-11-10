/*
    Author: JohnnyShootos (Edited by TheTimidShade)

    Description:
        Serverside call to create zeus module using passed player

    Parameters:
        0: OBJECT - Player to assign curator module to
        
    Returns:
        NONE
*/

#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

params [["_player", objNull, [objNull]]];

// Only an admin by the server's records may hand out Zeus (review S4).
if (!isServer || {isNull _player} || {!([] call EFUNC(common,senderIsAdmin))}) exitWith {
    WARNING_1("createZeusModule refused: machine %1 is not an admin",remoteExecutedOwner);
};

if (isNull admp_admin_zeusLogicGroup) then { // if the logic group doesn't exist, create a new one
    admp_admin_zeusLogicGroup = createGroup sideLogic;
    publicVariable "admp_admin_zeusLogicGroup";
};

// create module and assign player
private _curatorModule = admp_admin_zeusLogicGroup createUnit ["ModuleCurator_F", [0, 90, 90], [], 0.5, "NONE"];
_player assignCurator _curatorModule;
_player setVariable ['curatorModule', _curatorModule];

// Set up Zeus variables
_curatorModule setVariable ["owner", str (owner _player), true];
_curatorModule setVariable ["curatorUnitOwner", str (owner _player)];
_curatorModule addEventHandler ["CuratorObjectDoubleClicked",{(_this select 1) call bis_fnc_showCuratorAttributes;}];
_curatorModule addEventHandler ["CuratorGroupDoubleClicked",{(_this select 1) call bis_fnc_showCuratorAttributes;}];
_curatorModule addEventHandler ["CuratorWaypointDoubleClicked",{(_this select 1) call bis_fnc_showCuratorAttributes;}];
_curatorModule addEventHandler ["CuratorMarkerDoubleClicked",{(_this select 1) call bis_fnc_showCuratorAttributes;}];
_curatorModule addEventHandler ["CuratorFeedbackMessage",{_this call bis_fnc_showCuratorFeedbackMessage;}];
_curatorModule addEventHandler ["CuratorPinged",{_this call bis_fnc_curatorPinged;}];
_curatorModule addEventHandler ["CuratorObjectPlaced",{_this call bis_fnc_curatorObjectPlaced;}];
_curatorModule addEventHandler ["CuratorObjectEdited",{_this call bis_fnc_curatorObjectEdited;}];
_curatorModule addEventHandler ["CuratorWaypointPlaced",{_this call bis_fnc_curatorWaypointPlaced;}];

[_player, _curatorModule] call admp_fnc_updateCuratorEditableObjects // start updating editable objects
